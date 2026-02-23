import Foundation
import Combine

/// 맞고 게임 핵심 엔진
class MatchGoEngine: ObservableObject {
    @Published var state: GameState
    let rules: GameRules
    let scoreCalculator: ScoreCalculator
    var aiPlayer: AIStrategy?

    private var cancellables = Set<AnyCancellable>()

    init(rules: GameRules = .standard) {
        self.rules = rules
        self.state = GameState()
        self.scoreCalculator = ScoreCalculator(rules: rules)

        // GameState 내부 @Published 변경을 엔진 레벨로 전파
        state.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - 게임 시작

    func startNewGame() {
        state.reset()

        // 카드 배분
        let dealResult = CardDealer.dealForMatchGo()
        state.humanPlayer.hand = dealResult.playerHand
        state.aiPlayer.hand = dealResult.aiHand
        state.tableCards = dealResult.tableCards
        state.deck = dealResult.deck

        // 바닥 초기 상태 확인 (4장 같은 월 등)
        let tableCheck = CardDealer.checkInitialTable(
            tableCards: state.tableCards,
            dealerID: .human
        )
        state.tableCards = tableCheck.processedTableCards
        for (playerID, cards) in tableCheck.bonusCards {
            state.player(for: playerID).addToCaptured(cards)
        }
        for event in tableCheck.events {
            state.addLog(event)
        }

        // 손패 특수 상태 확인 (총통, 흔듦)
        checkHandSpecials(for: state.humanPlayer)
        checkHandSpecials(for: state.aiPlayer)

        state.currentTurn = .human
        state.phase = .playerTurnSelectCard
        state.addLog("게임 시작! 패를 선택하세요.")

        updateScores()
    }

    // MARK: - 손패 특수 확인

    private func checkHandSpecials(for player: Player) {
        let specials = CardDealer.checkHandSpecials(hand: player.hand)

        // 총통: 같은 월 4장
        if rules.enableChongTong && !specials.bombMonths.isEmpty {
            state.addLog("\(player.id.displayName): 총통! (\(specials.bombMonths.map { $0.shortName }.joined(separator: ", ")))")
            state.winner = player.id
            state.phase = .gameOver
            state.lastEvent = .chongTong
            return
        }

        // 흔듦: 같은 월 3장
        if rules.enableShake {
            for month in specials.shakeMonths {
                player.shakeCount += 1
                state.addLog("\(player.id.displayName): \(month.shortName) 흔듦!")
                state.lastEvent = .shake(player.handCardsForMonth(month))
            }
        }
    }

    // MARK: - 플레이어 턴: 카드 선택

    /// 플레이어가 손패에서 카드를 선택
    func playerSelectCard(_ card: Card) {
        guard state.phase == .playerTurnSelectCard else { return }
        guard state.humanPlayer.hand.contains(where: { $0.id == card.id }) else { return }

        state.selectedHandCard = card
        let matchResult = CardMatcher.findMatches(card: card, tableCards: state.tableCards)

        switch matchResult {
        case .twoMatch(let matchable):
            // 바닥에 2장 매칭 → 플레이어가 선택해야 함
            state.matchableTableCards = matchable
            state.phase = .playerTurnSelectMatch

        default:
            // 자동 처리 가능
            executePlayerHandPlay(card: card, selectedTableCard: nil)
        }
    }

    /// 바닥 카드 중 매칭할 카드 선택 (2장일 때)
    func playerSelectTableMatch(_ tableCard: Card) {
        guard state.phase == .playerTurnSelectMatch else { return }
        guard let handCard = state.selectedHandCard else { return }

        state.matchableTableCards.removeAll()
        executePlayerHandPlay(card: handCard, selectedTableCard: tableCard)
    }

    // MARK: - 손패 카드 플레이 실행

    private func executePlayerHandPlay(card: Card, selectedTableCard: Card?) {
        let player = state.humanPlayer
        player.removeFromHand(card)

        var tableCards = state.tableCards
        let (captured, _) = CardMatcher.executeHandMatch(
            playedCard: card,
            selectedTableCard: selectedTableCard,
            tableCards: &tableCards
        )
        state.tableCards = tableCards

        if captured.isEmpty {
            state.addLog("\(card.name) → 바닥에 놓음")
            state.lastEvent = .noMatch
        } else {
            let capturedNames = captured.map { $0.name }.joined(separator: ", ")
            state.addLog("\(card.name) → \(capturedNames) 먹음")
            state.lastEvent = .matched(card, captured.first!)
        }

        // 임시로 캡쳐된 카드 보관 (덱 뒤집기 후 최종 처리)
        state.selectedHandCard = card

        // 덱에서 카드 뒤집기
        state.phase = .playerTurnFlipDeck
        flipDeckCard(capturedFromHand: captured)
    }

    // MARK: - 덱 카드 뒤집기

    func flipDeckCard(capturedFromHand: [Card]) {
        guard !state.deck.isEmpty else {
            // 덱이 비었으면 턴 종료
            finalizeTurn(player: state.humanPlayer, capturedCards: capturedFromHand)
            return
        }

        let flippedCard = state.deck.removeFirst()
        state.flippedDeckCard = flippedCard
        state.addLog("덱에서 \(flippedCard.name) 뒤집음")

        let flipMatchResult = CardMatcher.findMatches(card: flippedCard, tableCards: state.tableCards)

        switch flipMatchResult {
        case .twoMatch(let matchable):
            // 뻑 체크: 뒤집은 카드가 바닥 2장과 매칭
            state.matchableTableCards = matchable
            // 뻑 처리: 바닥에 놓기
            state.tableCards.append(flippedCard)
            state.addLog("뻑! \(flippedCard.month.shortName)")
            state.lastEvent = .ppuk
            finalizeTurn(player: state.humanPlayer, capturedCards: capturedFromHand)

        default:
            // 자동 처리
            executeFlipPlay(flippedCard: flippedCard, capturedFromHand: capturedFromHand)
        }
    }

    private func executeFlipPlay(flippedCard: Card, capturedFromHand: [Card]) {
        let handPlayedCard: Card? = capturedFromHand.isEmpty ? state.selectedHandCard : nil

        var tableCards = state.tableCards
        let (flipCaptured, isJjok, _) = CardMatcher.executeFlipMatch(
            flippedCard: flippedCard,
            selectedTableCard: nil,
            tableCards: &tableCards,
            handPlayedCard: handPlayedCard
        )
        state.tableCards = tableCards

        var allCaptured = capturedFromHand + flipCaptured

        if isJjok {
            state.addLog("쪽!")
            state.lastEvent = .jjok
        }

        if !flipCaptured.isEmpty {
            let names = flipCaptured.map { $0.name }.joined(separator: ", ")
            state.addLog("뒤집기로 \(names) 먹음")
        }

        // 쓸 체크
        let isSsul = CardMatcher.checkSsul(tableCards: state.tableCards) && !allCaptured.isEmpty
        if isSsul {
            state.addLog("쓸! 바닥을 싹 쓸어감!")
            state.lastEvent = .ssul
        }

        finalizeTurn(player: state.humanPlayer, capturedCards: allCaptured)
    }

    // MARK: - 턴 마무리

    private func finalizeTurn(player: Player, capturedCards: [Card]) {
        // 획득 카드 추가
        player.addToCaptured(capturedCards)

        // 특별 획득 이벤트 체크
        checkCaptureEvents(player: player, captured: capturedCards)

        // 점수 업데이트
        updateScores()

        state.selectedHandCard = nil
        state.flippedDeckCard = nil
        state.matchableTableCards.removeAll()

        // 고/스톱 체크
        if scoreCalculator.canCallGoOrStop(player: player) && player.goCount == 0 {
            // 처음 기준점 달성
            if player.id == .human {
                state.phase = .playerTurnGoStop
            } else {
                state.phase = .aiTurnGoStop
            }
            return
        } else if scoreCalculator.canCallGoOrStop(player: player) && player.goCount > 0 {
            // 이미 고를 한 상태에서 추가 점수 획득
            let baseScore = scoreCalculator.calculateBaseScore(for: player)
            let previousScore = player.id == .human ? state.humanScore : state.aiScore
            if baseScore > previousScore {
                if player.id == .human {
                    state.phase = .playerTurnGoStop
                } else {
                    state.phase = .aiTurnGoStop
                }
                return
            }
        }

        // 게임 종료 체크 (양쪽 손패 모두 소진)
        if state.humanPlayer.hand.isEmpty && state.aiPlayer.hand.isEmpty {
            handleNagari()
            return
        }

        // 다음 턴으로
        switchTurn()
    }

    // MARK: - 고/스톱

    /// 플레이어가 고 선언
    func playerCallGo() {
        guard state.phase == .playerTurnGoStop else { return }
        state.humanPlayer.goCount += 1
        state.addLog("고! (\(state.humanPlayer.goCount)회)")
        state.lastEvent = .goDecision
        updateScores()
        switchTurn()
    }

    /// 플레이어가 스톱 선언
    func playerCallStop() {
        guard state.phase == .playerTurnGoStop else { return }
        state.addLog("스톱!")
        state.lastEvent = .stopDecision
        endRound(winner: .human)
    }

    // MARK: - AI 턴

    func executeAITurn() {
        guard state.phase == .aiTurn else { return }

        let ai = state.aiPlayer
        guard !ai.hand.isEmpty else {
            switchTurn()
            return
        }

        // AI 카드 선택 (aiPlayer 전략 또는 기본)
        let (cardToPlay, tableCardToMatch) = aiSelectCard()

        ai.removeFromHand(cardToPlay)

        var tableCards = state.tableCards
        let (handCaptured, _) = CardMatcher.executeHandMatch(
            playedCard: cardToPlay,
            selectedTableCard: tableCardToMatch,
            tableCards: &tableCards
        )
        state.tableCards = tableCards

        if handCaptured.isEmpty {
            state.addLog("AI: \(cardToPlay.name) → 바닥에 놓음")
        } else {
            state.addLog("AI: \(cardToPlay.name) → 매칭 성공")
        }

        // 덱에서 뒤집기
        var allCaptured = handCaptured

        if !state.deck.isEmpty {
            let flipped = state.deck.removeFirst()
            state.addLog("AI: 덱에서 \(flipped.name) 뒤집음")

            let flipMatch = CardMatcher.findMatches(card: flipped, tableCards: state.tableCards)

            switch flipMatch {
            case .twoMatch:
                state.tableCards.append(flipped)
                state.addLog("AI: 뻑!")
                state.lastEvent = .ppuk

            default:
                let handPlayedCard: Card? = handCaptured.isEmpty ? cardToPlay : nil
                var tCards = state.tableCards
                let (flipCaptured, isJjok, _) = CardMatcher.executeFlipMatch(
                    flippedCard: flipped,
                    selectedTableCard: nil,
                    tableCards: &tCards,
                    handPlayedCard: handPlayedCard
                )
                state.tableCards = tCards
                allCaptured += flipCaptured

                if isJjok {
                    state.addLog("AI: 쪽!")
                    state.lastEvent = .jjok
                }
            }
        }

        // 쓸 체크
        if CardMatcher.checkSsul(tableCards: state.tableCards) && !allCaptured.isEmpty {
            state.addLog("AI: 쓸!")
            state.lastEvent = .ssul
        }

        finalizeTurn(player: ai, capturedCards: allCaptured)
    }

    /// AI 고/스톱 결정
    func executeAIGoStopDecision() {
        guard state.phase == .aiTurnGoStop else { return }

        let score = scoreCalculator.calculateBaseScore(for: state.aiPlayer)

        // 기본 AI 고/스톱 로직
        let shouldGo: Bool
        if let strategy = aiPlayer {
            shouldGo = strategy.shouldCallGo(
                state: state,
                currentScore: score,
                goCount: state.aiPlayer.goCount
            )
        } else {
            // 기본: 점수 낮으면 고, 높으면 스톱
            shouldGo = score < 10 && state.aiPlayer.goCount < 3
        }

        if shouldGo {
            state.aiPlayer.goCount += 1
            state.addLog("AI: 고! (\(state.aiPlayer.goCount)회)")
            state.lastEvent = .goDecision
            updateScores()
            switchTurn()
        } else {
            state.addLog("AI: 스톱!")
            state.lastEvent = .stopDecision
            endRound(winner: .ai)
        }
    }

    // MARK: - AI 카드 선택 (기본)

    private func aiSelectCard() -> (Card, Card?) {
        if let strategy = aiPlayer {
            return strategy.selectCard(state: state)
        }

        // 기본 AI: 매칭 가능한 카드 우선, 없으면 가장 불필요한 카드
        let hand = state.aiPlayer.hand

        // 매칭 가능한 카드 찾기
        for card in hand {
            let match = CardMatcher.findMatches(card: card, tableCards: state.tableCards)
            switch match {
            case .oneMatch, .threeMatch:
                return (card, nil)
            case .twoMatch(let options):
                // 더 높은 가치의 카드 선택
                let best = options.sorted { cardValue($0) > cardValue($1) }.first
                return (card, best)
            default:
                continue
            }
        }

        // 매칭 불가 → 가장 가치 낮은 카드 버리기
        let sorted = hand.sorted { cardValue($0) < cardValue($1) }
        return (sorted.first!, nil)
    }

    private func cardValue(_ card: Card) -> Int {
        switch card.type {
        case .bright:     return 100
        case .animal:     return card.isGodoriCard ? 50 : 30
        case .ribbon:     return 20
        case .doubleJunk: return 5
        case .junk:       return 1
        }
    }

    // MARK: - 턴 전환

    private func switchTurn() {
        if state.currentTurn == .human {
            state.currentTurn = .ai
            state.phase = .aiTurn
        } else {
            state.currentTurn = .human
            state.phase = .playerTurnSelectCard
        }
    }

    // MARK: - 라운드 종료

    private func endRound(winner winnerID: PlayerID) {
        let winner = state.player(for: winnerID)
        let loser = state.opponent(of: winnerID)

        let (finalScore, multipliers) = scoreCalculator.calculateFinalScore(
            winner: winner,
            loser: loser,
            nagariMultiplier: state.nagariMultiplier
        )

        state.winner = winnerID
        state.finalScore = finalScore
        state.scoreMultipliers = multipliers
        state.phase = .roundEnd

        state.addLog("━━━ 게임 종료 ━━━")
        state.addLog("\(winnerID.displayName) 승리! 최종 점수: \(finalScore)점")
        for m in multipliers {
            state.addLog("  \(m)")
        }
    }

    // MARK: - 나가리

    private func handleNagari() {
        state.isNagari = true
        state.phase = .nagari
        state.nagariMultiplier *= 2
        state.addLog("나가리! 다음 판 배수 ×\(state.nagariMultiplier)")
    }

    // MARK: - 점수 업데이트

    func updateScores() {
        state.humanScore = scoreCalculator.calculateBaseScore(for: state.humanPlayer)
        state.aiScore = scoreCalculator.calculateBaseScore(for: state.aiPlayer)
    }

    // MARK: - 이벤트 체크

    private func checkCaptureEvents(player: Player, captured: [Card]) {
        for card in captured {
            if card.isBright {
                state.lastEvent = .brightCaptured(card)
                state.addLog("광 획득! \(card.name)")
            }
        }

        if player.hasGodori && !captured.filter({ $0.isGodoriCard }).isEmpty {
            state.lastEvent = .godoriComplete
            state.addLog("고도리 완성!")
        }

        if player.redPoetryRibbons.count >= 3 {
            let newRedPoetry = captured.filter { $0.ribbonType == .redPoetry }
            if !newRedPoetry.isEmpty {
                state.lastEvent = .ribbonSetComplete(.redPoetry)
                state.addLog("홍단 완성!")
            }
        }

        if player.bluePlainRibbons.count >= 3 {
            let newBlue = captured.filter { $0.ribbonType == .bluePlain }
            if !newBlue.isEmpty {
                state.lastEvent = .ribbonSetComplete(.bluePlain)
                state.addLog("청단 완성!")
            }
        }

        if player.redPlainRibbons.count >= 3 {
            let newRedPlain = captured.filter { $0.ribbonType == .redPlain }
            if !newRedPlain.isEmpty {
                state.lastEvent = .ribbonSetComplete(.redPlain)
                state.addLog("초단 완성!")
            }
        }
    }

    // MARK: - 나가리 후 재시작

    func restartAfterNagari() {
        let multiplier = state.nagariMultiplier
        state.reset()
        state.nagariMultiplier = multiplier
        state.roundNumber += 1
        startNewGame()
    }
}
