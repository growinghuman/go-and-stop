import SpriteKit
import Combine

/// 맞고 게임 메인 SpriteKit 씬
class GameScene: SKScene {
    // MARK: - Properties

    var engine: MatchGoEngine!
    var effectManager: EffectManager!
    var onSoundEvent: ((SoundEvent) -> Void)?
    var onPhaseChange: ((GamePhase) -> Void)?

    private var cardNodes: [String: CardNode] = [:]
    private var cancellables = Set<AnyCancellable>()

    // 레이아웃 상수
    private var tableCenter: CGPoint { CGPoint(x: size.width / 2, y: size.height * 0.48) }
    private var humanHandY: CGFloat { size.height * 0.12 }
    private var aiHandY: CGFloat { size.height * 0.88 }
    private var humanCapturedY: CGFloat { size.height * 0.25 }
    private var aiCapturedY: CGFloat { size.height * 0.75 }
    private var deckPosition: CGPoint { CGPoint(x: size.width - 45, y: size.height * 0.48) }

    // 상태
    private var isAnimating = false
    private var selectedCardNode: CardNode?

    // 배경
    private var backgroundNode: SKSpriteNode!

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        setupBackground()
        effectManager = EffectManager(scene: self)

        if engine != nil {
            setupObservers()
        }
    }

    func configure(engine: MatchGoEngine) {
        self.engine = engine
        if self.view != nil {
            setupObservers()
        }
    }

    // MARK: - Setup

    private func setupBackground() {
        backgroundColor = UIColor(red: 0.07, green: 0.27, blue: 0.17, alpha: 1)

        // 바닥판 텍스쳐 (초록 매트 느낌)
        let bgSize = self.size
        let bg = SKShapeNode(rectOf: bgSize)
        bg.fillColor = UIColor(red: 0.08, green: 0.30, blue: 0.18, alpha: 1)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: bgSize.width / 2, y: bgSize.height / 2)
        bg.zPosition = -10
        addChild(bg)

        // 중앙 영역 표시 (바닥 카드 놓이는 영역)
        let tableArea = SKShapeNode(rectOf: CGSize(width: bgSize.width - 30, height: bgSize.height * 0.25), cornerRadius: 10)
        tableArea.fillColor = UIColor(red: 0.05, green: 0.22, blue: 0.13, alpha: 0.5)
        tableArea.strokeColor = UIColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 0.3)
        tableArea.lineWidth = 1
        tableArea.position = tableCenter
        tableArea.zPosition = -5
        addChild(tableArea)

        // 구분선
        let dividerTop = createDivider(y: size.height * 0.62)
        let dividerBottom = createDivider(y: size.height * 0.34)
        addChild(dividerTop)
        addChild(dividerBottom)

        // 덱 위치 표시
        let deckArea = SKShapeNode(rectOf: CardNode.cardSize, cornerRadius: CardNode.cornerRadius)
        deckArea.fillColor = UIColor.black.withAlphaComponent(0.2)
        deckArea.strokeColor = UIColor.white.withAlphaComponent(0.2)
        deckArea.lineWidth = 1
        deckArea.position = deckPosition
        deckArea.zPosition = -1
        addChild(deckArea)
    }

    private func createDivider(y: CGFloat) -> SKShapeNode {
        let line = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: 1))
        line.fillColor = UIColor.white.withAlphaComponent(0.1)
        line.strokeColor = .clear
        line.position = CGPoint(x: size.width / 2, y: y)
        line.zPosition = -3
        return line
    }

    // MARK: - Observers

    private func setupObservers() {
        engine.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
                self?.onPhaseChange?(state.phase)
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: GameState) {
        // 이벤트 기반 연출 자동 재생
        if state.lastEvent != .none && state.lastEvent != .noMatch {
            playEvent(state.lastEvent)
        }

        // 매칭 가능 카드 하이라이트
        if state.phase == .playerTurnSelectMatch && !state.matchableTableCards.isEmpty {
            highlightMatchableCards(state.matchableTableCards)
        }

        // 레이아웃 갱신
        refreshLayout()
    }

    // MARK: - 게임 시작 연출

    func dealCards(completion: @escaping () -> Void) {
        guard let engine = engine else { return }
        isAnimating = true
        clearAllCards()

        let state = engine.state

        // 덱 노드 표시
        let deckBackNode = CardNode(card: Card.createDeck()[0], faceUp: false)
        deckBackNode.position = deckPosition
        deckBackNode.name = "deck_display"
        deckBackNode.zPosition = 5
        addChild(deckBackNode)

        var delay: TimeInterval = 0
        let dealDuration: TimeInterval = 0.1

        // 바닥 카드 배분
        for (i, card) in state.tableCards.enumerated() {
            let node = createCardNode(card: card, faceUp: true)
            node.position = deckPosition
            node.zPosition = CGFloat(10 + i)
            addChild(node)

            let destX = calculateTableCardX(index: i, total: state.tableCards.count)
            let dest = CGPoint(x: destX, y: tableCenter.y)

            let wait = SKAction.wait(forDuration: delay)
            let move = SKAction.move(to: dest, duration: dealDuration)
            move.timingMode = .easeOut

            node.run(SKAction.sequence([wait, move])) {
                self.onSoundEvent?(.cardDeal)
            }
            delay += 0.06
        }

        // AI 손패 (뒷면)
        for (i, card) in state.aiPlayer.hand.enumerated() {
            let node = createCardNode(card: card, faceUp: false)
            node.position = deckPosition
            node.zPosition = CGFloat(20 + i)
            addChild(node)

            let destX = calculateHandCardX(index: i, total: state.aiPlayer.hand.count)
            let dest = CGPoint(x: destX, y: aiHandY)

            let wait = SKAction.wait(forDuration: delay)
            let move = SKAction.move(to: dest, duration: dealDuration)
            move.timingMode = .easeOut

            node.run(SKAction.sequence([wait, move])) {
                self.onSoundEvent?(.cardDeal)
            }
            delay += 0.04
        }

        // 플레이어 손패 (앞면)
        for (i, card) in state.humanPlayer.hand.enumerated() {
            let node = createCardNode(card: card, faceUp: true)
            node.position = deckPosition
            node.zPosition = CGFloat(30 + i)
            node.isUserInteractionEnabled = false
            addChild(node)

            let destX = calculateHandCardX(index: i, total: state.humanPlayer.hand.count)
            let dest = CGPoint(x: destX, y: humanHandY)

            let wait = SKAction.wait(forDuration: delay)
            let move = SKAction.move(to: dest, duration: dealDuration)
            move.timingMode = .easeOut

            node.run(SKAction.sequence([wait, move])) {
                self.onSoundEvent?(.cardDeal)
            }
            delay += 0.04
        }

        // 모든 배분 완료 후
        run(SKAction.wait(forDuration: delay + 0.3)) {
            self.isAnimating = false
            completion()
        }
    }

    // MARK: - 카드 노드 관리

    private func createCardNode(card: Card, faceUp: Bool) -> CardNode {
        let node = CardNode(card: card, faceUp: faceUp)
        cardNodes[card.id] = node
        return node
    }

    func getCardNode(for card: Card) -> CardNode? {
        return cardNodes[card.id]
    }

    func clearAllCards() {
        for (_, node) in cardNodes {
            node.removeFromParent()
        }
        cardNodes.removeAll()
        childNode(withName: "deck_display")?.removeFromParent()
    }

    // MARK: - 레이아웃 계산

    func calculateHandCardX(index: Int, total: Int) -> CGFloat {
        let spacing: CGFloat = min(CardNode.cardWidth + 4, (size.width - 30) / CGFloat(total))
        let totalWidth = spacing * CGFloat(total - 1)
        let startX = (size.width - totalWidth) / 2
        return startX + spacing * CGFloat(index)
    }

    func calculateTableCardX(index: Int, total: Int) -> CGFloat {
        let maxPerRow = 8
        let row = index / maxPerRow
        let col = index % maxPerRow
        let itemsInRow = min(total - row * maxPerRow, maxPerRow)

        let spacing: CGFloat = min(CardNode.cardWidth + 6, (size.width - 80) / CGFloat(itemsInRow))
        let totalWidth = spacing * CGFloat(itemsInRow - 1)
        let startX = (size.width - totalWidth) / 2
        let y = tableCenter.y + CGFloat(row) * (CardNode.cardHeight + 5) - CGFloat(row) * (CardNode.cardHeight / 2)

        let node = CGPoint(x: startX + spacing * CGFloat(col), y: y)
        return node.x
    }

    func calculateTableCardPosition(index: Int, total: Int) -> CGPoint {
        let maxPerRow = 8
        let row = index / maxPerRow
        let col = index % maxPerRow
        let itemsInRow = min(total - row * maxPerRow, maxPerRow)

        let spacing: CGFloat = min(CardNode.cardWidth + 6, (size.width - 80) / CGFloat(itemsInRow))
        let totalWidth = spacing * CGFloat(itemsInRow - 1)
        let startX = (size.width - totalWidth) / 2

        let rowOffset: CGFloat = row > 0 ? -55 : 0
        return CGPoint(x: startX + spacing * CGFloat(col), y: tableCenter.y + rowOffset)
    }

    // MARK: - 터치 처리

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isAnimating, let touch = touches.first, let engine = engine else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        switch engine.state.phase {
        case .playerTurnSelectCard:
            handleCardSelection(touchedNodes: touchedNodes, location: location)

        case .playerTurnSelectMatch:
            handleTableCardSelection(touchedNodes: touchedNodes)

        default:
            break
        }
    }

    private func handleCardSelection(touchedNodes: [SKNode], location: CGPoint) {
        for node in touchedNodes {
            if let cardNode = node as? CardNode,
               engine.state.humanPlayer.hand.contains(where: { $0.id == cardNode.card.id }) {
                // 카드 선택 애니메이션
                selectedCardNode?.isHighlighted = false
                cardNode.isHighlighted = true
                cardNode.playTapAnimation()
                selectedCardNode = cardNode

                onSoundEvent?(.cardPlay)
                engine.playerSelectCard(cardNode.card)

                // 선택된 카드 애니메이션
                animateCardPlay(cardNode: cardNode)
                return
            }
        }
    }

    private func handleTableCardSelection(touchedNodes: [SKNode]) {
        let matchable = engine.state.matchableTableCards
        for node in touchedNodes {
            if let cardNode = node as? CardNode,
               matchable.contains(where: { $0.id == cardNode.card.id }) {
                cardNode.playTapAnimation()
                onSoundEvent?(.cardMatch)

                // 하이라이트 제거
                for mc in matchable {
                    cardNodes[mc.id]?.setSelectable(false)
                }

                engine.playerSelectTableMatch(cardNode.card)
                return
            }
        }
    }

    // MARK: - 애니메이션 실행

    func animateCardPlay(cardNode: CardNode) {
        isAnimating = true
        let dest = tableCenter
        cardNode.moveTo(dest, duration: 0.2) {
            self.isAnimating = false
        }
    }

    func highlightMatchableCards(_ cards: [Card]) {
        for card in cards {
            cardNodes[card.id]?.setSelectable(true)
            cardNodes[card.id]?.isHighlighted = true
        }
    }

    func animateFlipFromDeck(card: Card, completion: @escaping () -> Void) {
        isAnimating = true
        let node = createCardNode(card: card, faceUp: false)
        node.position = deckPosition
        node.zPosition = 50
        addChild(node)

        let moveToCenter = SKAction.move(to: tableCenter, duration: 0.2)
        moveToCenter.timingMode = .easeOut

        node.run(moveToCenter) {
            node.flip(toFaceUp: true) {
                self.onSoundEvent?(.cardFlip)
                self.isAnimating = false
                completion()
            }
        }
    }

    func animateCapture(cards: [Card], to playerID: PlayerID, completion: @escaping () -> Void) {
        isAnimating = true
        let destY = playerID == .human ? humanCapturedY : aiCapturedY

        let group = DispatchGroup()

        for (i, card) in cards.enumerated() {
            if let node = cardNodes[card.id] {
                group.enter()
                let dest = CGPoint(x: 30 + CGFloat(i) * 15, y: destY)
                let delay = SKAction.wait(forDuration: Double(i) * 0.05)
                let move = SKAction.move(to: dest, duration: 0.2)
                move.timingMode = .easeIn
                let scale = SKAction.scale(to: 0.6, duration: 0.2)

                node.run(SKAction.sequence([delay, SKAction.group([move, scale])])) {
                    self.onSoundEvent?(.cardMatch)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.isAnimating = false
            completion()
        }
    }

    // MARK: - 이벤트 연출

    func playEvent(_ event: TurnEvent) {
        switch event {
        case .ppuk:
            effectManager.showPpukEffect(at: tableCenter)
            onSoundEvent?(.ppuk)

        case .jjok:
            effectManager.showJjokEffect(at: tableCenter)
            onSoundEvent?(.jjok)

        case .ssul:
            effectManager.showSsulEffect()
            onSoundEvent?(.ssul)

        case .bomb:
            effectManager.showBombEffect(at: tableCenter)
            onSoundEvent?(.bomb)

        case .brightCaptured:
            effectManager.showBrightEffect(at: tableCenter)
            onSoundEvent?(.gwangHit)

        case .godoriComplete:
            effectManager.showGodoriEffect(at: tableCenter)
            onSoundEvent?(.godori)

        case .goDecision:
            let goCount = engine.state.currentTurn == .human ?
                engine.state.humanPlayer.goCount : engine.state.aiPlayer.goCount
            effectManager.showGoEffect(at: CGPoint(x: size.width / 2, y: size.height / 2), goCount: goCount)
            onSoundEvent?(.goCall)

        case .stopDecision:
            effectManager.showStopEffect(at: CGPoint(x: size.width / 2, y: size.height / 2))
            onSoundEvent?(.stopCall)

        case .shake:
            effectManager.showShakeEffect(at: tableCenter)
            onSoundEvent?(.shake)

        case .ribbonSetComplete(let ribbonType):
            let text: String
            switch ribbonType {
            case .redPoetry: text = "홍단!"
            case .bluePlain: text = "청단!"
            case .redPlain:  text = "초단!"
            case .none: return
            }
            effectManager.showBigText(text, color: .systemOrange, at: CGPoint(x: size.width / 2, y: size.height / 2), fontSize: 36)
            onSoundEvent?(.cardMatch)

        default:
            break
        }
    }

    // MARK: - 승리/패배 연출

    func playWinEffect() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        effectManager.showWinEffect(at: center)
        onSoundEvent?(.winCheer)
    }

    func playLoseEffect() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        effectManager.showLoseEffect(at: center)
        onSoundEvent?(.loseSigh)
    }

    // MARK: - 레이아웃 갱신

    func refreshLayout() {
        guard let engine = engine else { return }
        let state = engine.state

        // 바닥 카드 위치 재조정
        for (i, card) in state.tableCards.enumerated() {
            if let node = cardNodes[card.id] {
                let pos = calculateTableCardPosition(index: i, total: state.tableCards.count)
                node.run(SKAction.move(to: pos, duration: 0.15))
            }
        }

        // 플레이어 손패 재조정
        for (i, card) in state.humanPlayer.hand.enumerated() {
            if let node = cardNodes[card.id] {
                let x = calculateHandCardX(index: i, total: state.humanPlayer.hand.count)
                node.run(SKAction.move(to: CGPoint(x: x, y: humanHandY), duration: 0.15))
                node.zPosition = CGFloat(30 + i)
            }
        }

        // AI 손패 재조정
        for (i, card) in state.aiPlayer.hand.enumerated() {
            if let node = cardNodes[card.id] {
                let x = calculateHandCardX(index: i, total: state.aiPlayer.hand.count)
                node.run(SKAction.move(to: CGPoint(x: x, y: aiHandY), duration: 0.15))
            }
        }
    }
}

// MARK: - Sound Events

enum SoundEvent {
    case cardDeal
    case cardPlay
    case cardMatch
    case cardFlip
    case goCall
    case stopCall
    case bomb
    case shake
    case winCheer
    case winBig
    case loseSigh
    case gwangHit
    case godori
    case ppuk
    case ssul
    case jjok
}
