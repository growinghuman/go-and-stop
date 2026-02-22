import SpriteKit

/// 화투 카드 SpriteKit 노드
class CardNode: SKSpriteNode {
    let card: Card
    var isFaceUp: Bool = true
    var isSelectable: Bool = false
    var isHighlighted: Bool = false {
        didSet { updateHighlight() }
    }

    // 카드 크기 상수
    static let cardWidth: CGFloat = 55
    static let cardHeight: CGFloat = 80
    static let cardSize = CGSize(width: cardWidth, height: cardHeight)
    static let miniCardSize = CGSize(width: 35, height: 50)
    static let cornerRadius: CGFloat = 6

    // 애니메이션 속도 (게임 속도에 따라 조절)
    static var animationSpeed: CGFloat = 1.0

    private var frontTexture: SKTexture
    private let backTexture: SKTexture

    init(card: Card, faceUp: Bool = true) {
        self.card = card
        self.isFaceUp = faceUp

        // 텍스쳐 캐시 사용 (성능 최적화)
        self.frontTexture = TextureCache.shared.cardTexture(for: card)
        self.backTexture = TextureCache.shared.cardBackTexture()

        let texture = faceUp ? frontTexture : backTexture
        super.init(texture: texture, color: .clear, size: CardNode.cardSize)

        self.name = card.id
        self.isUserInteractionEnabled = false
        self.zPosition = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 카드 텍스쳐 생성 (프로그래매틱)

    static func createCardTexture(for card: Card) -> SKTexture {
        let size = cardSize
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let ctx = context.cgContext

            // 카드 배경 (흰색, 둥근 모서리)
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: cornerRadius)
            ctx.setShadow(offset: CGSize(width: 1, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.3).cgColor)

            UIColor.white.setFill()
            path.fill()

            ctx.setShadow(offset: .zero, blur: 0)

            // 카드 테두리
            UIColor.darkGray.setStroke()
            path.lineWidth = 0.5
            path.stroke()

            // 월 표시 (상단)
            let monthColor = cardTypeColor(card.type)
            let monthBg = CGRect(x: 2, y: 2, width: size.width - 4, height: 18)
            let monthPath = UIBezierPath(roundedRect: monthBg,
                                         byRoundingCorners: [.topLeft, .topRight],
                                         cornerRadii: CGSize(width: cornerRadius - 1, height: cornerRadius - 1))
            monthColor.setFill()
            monthPath.fill()

            // 월 텍스트
            let monthText = card.month.shortName as NSString
            let monthAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.white
            ]
            let monthSize = monthText.size(withAttributes: monthAttrs)
            monthText.draw(at: CGPoint(x: (size.width - monthSize.width) / 2, y: 3), withAttributes: monthAttrs)

            // 카드 타입 아이콘 (중앙)
            let typeEmoji = cardTypeEmoji(card) as NSString
            let emojiAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28)
            ]
            let emojiSize = typeEmoji.size(withAttributes: emojiAttrs)
            typeEmoji.draw(at: CGPoint(x: (size.width - emojiSize.width) / 2,
                                       y: (size.height - emojiSize.height) / 2 + 2),
                          withAttributes: emojiAttrs)

            // 카드 타입 텍스트 (하단)
            let typeText = card.type.displayName as NSString
            let typeAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: monthColor
            ]
            let typeSize = typeText.size(withAttributes: typeAttrs)
            typeText.draw(at: CGPoint(x: (size.width - typeSize.width) / 2,
                                     y: size.height - 14),
                         withAttributes: typeAttrs)

            // 광 표시
            if card.isBright {
                let gwangText = "光" as NSString
                let gwangAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
                ]
                gwangText.draw(at: CGPoint(x: size.width - 18, y: size.height - 20), withAttributes: gwangAttrs)
            }

            // 리본 타입 표시
            if card.type == .ribbon && card.ribbonType != .none {
                let ribbonColor: UIColor
                switch card.ribbonType {
                case .redPoetry: ribbonColor = .systemRed
                case .bluePlain: ribbonColor = .systemBlue
                case .redPlain:  ribbonColor = .systemOrange
                case .none:      ribbonColor = .clear
                }
                let dot = CGRect(x: 4, y: size.height - 12, width: 8, height: 8)
                ribbonColor.setFill()
                UIBezierPath(ovalIn: dot).fill()
            }
        }

        return SKTexture(image: image)
    }

    static func createBackTexture() -> SKTexture {
        let size = cardSize
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let ctx = context.cgContext

            // 둥근 모서리 배경
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: cornerRadius)
            ctx.setShadow(offset: CGSize(width: 1, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.3).cgColor)

            // 빨간색 뒷면
            UIColor(red: 0.8, green: 0.1, blue: 0.15, alpha: 1).setFill()
            path.fill()

            ctx.setShadow(offset: .zero, blur: 0)

            // 테두리
            UIColor(red: 0.6, green: 0.05, blue: 0.1, alpha: 1).setStroke()
            path.lineWidth = 1.5
            path.stroke()

            // 중앙 문양
            let innerRect = rect.insetBy(dx: 8, dy: 12)
            let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: 4)
            UIColor(red: 0.7, green: 0.08, blue: 0.12, alpha: 1).setFill()
            innerPath.fill()

            // 꽃 마크
            let flowerText = "🎴" as NSString
            let flowerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24)
            ]
            let flowerSize = flowerText.size(withAttributes: flowerAttrs)
            flowerText.draw(at: CGPoint(x: (size.width - flowerSize.width) / 2,
                                        y: (size.height - flowerSize.height) / 2),
                           withAttributes: flowerAttrs)
        }

        return SKTexture(image: image)
    }

    // MARK: - 카드별 이모지

    static func cardTypeEmoji(_ card: Card) -> String {
        switch (card.month, card.type) {
        // 광
        case (.january, .bright):   return "🐦" // 학
        case (.march, .bright):     return "🌸" // 커튼
        case (.august, .bright):    return "🌕" // 달
        case (.november, .bright):  return "🌿" // 오동
        case (.december, .bright):  return "☔" // 비

        // 열끗
        case (.february, .animal):  return "🐤" // 꾀꼬리
        case (.april, .animal):     return "🐦" // 두견
        case (.may, .animal):       return "🌉" // 다리
        case (.june, .animal):      return "🦋" // 나비
        case (.july, .animal):      return "🐗" // 멧돼지
        case (.august, .animal):    return "🦆" // 기러기
        case (.september, .animal): return "🍶" // 술잔
        case (.october, .animal):   return "🦌" // 사슴
        case (.december, .animal):  return "🐦" // 제비

        // 띠
        case (_, .ribbon):
            switch card.ribbonType {
            case .redPoetry: return "📜" // 홍단
            case .bluePlain: return "🔵" // 청단
            case .redPlain:  return "🔴" // 초단
            case .none:      return "🎀"
            }

        // 피/쌍피
        case (_, .doubleJunk): return "🍃🍃"
        case (_, .junk):       return "🍃"

        default: return "🎴"
        }
    }

    // MARK: - 타입별 색상

    static func cardTypeColor(_ type: CardType) -> UIColor {
        switch type {
        case .bright:     return UIColor(red: 0.85, green: 0.65, blue: 0, alpha: 1) // 금색
        case .animal:     return UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1) // 초록
        case .ribbon:     return UIColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1) // 빨강
        case .junk:       return UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1) // 회색
        case .doubleJunk: return UIColor(red: 0.4, green: 0.6, blue: 0.4, alpha: 1) // 연두
        }
    }

    // MARK: - 카드 뒤집기 애니메이션

    func flip(toFaceUp: Bool, completion: (() -> Void)? = nil) {
        let duration = 0.3 / Double(CardNode.animationSpeed)

        let scaleDown = SKAction.scaleX(to: 0.01, duration: duration / 2)
        scaleDown.timingMode = .easeIn

        let changeTexture = SKAction.run { [weak self] in
            self?.texture = toFaceUp ? self?.frontTexture : self?.backTexture
            self?.isFaceUp = toFaceUp
        }

        let scaleUp = SKAction.scaleX(to: 1.0, duration: duration / 2)
        scaleUp.timingMode = .easeOut

        let sequence = SKAction.sequence([scaleDown, changeTexture, scaleUp])
        run(sequence) {
            completion?()
        }
    }

    // MARK: - 하이라이트

    private func updateHighlight() {
        if isHighlighted {
            let glow = SKEffectNode()
            glow.name = "glow"
            glow.shouldRasterize = true
            // 노란색 테두리로 하이라이트
            let border = SKShapeNode(rectOf: CGSize(width: CardNode.cardWidth + 4, height: CardNode.cardHeight + 4), cornerRadius: cornerRadius)
            border.strokeColor = .systemYellow
            border.lineWidth = 3
            border.fillColor = .clear
            border.glowWidth = 3
            border.name = "highlight_border"
            addChild(border)
        } else {
            childNode(withName: "highlight_border")?.removeFromParent()
            childNode(withName: "glow")?.removeFromParent()
        }
    }

    // MARK: - 카드 이동 애니메이션

    func moveTo(_ destination: CGPoint, duration: TimeInterval = 0.25, completion: (() -> Void)? = nil) {
        let adjustedDuration = duration / Double(CardNode.animationSpeed)
        let move = SKAction.move(to: destination, duration: adjustedDuration)
        move.timingMode = .easeInEaseOut
        run(move) {
            completion?()
        }
    }

    func moveWithBounce(to destination: CGPoint, completion: (() -> Void)? = nil) {
        let duration = 0.2 / Double(CardNode.animationSpeed)
        let move = SKAction.move(to: destination, duration: duration)
        move.timingMode = .easeIn

        let overshoot = CGPoint(x: destination.x, y: destination.y - 5)
        let bounce1 = SKAction.move(to: overshoot, duration: 0.05 / Double(CardNode.animationSpeed))
        let bounce2 = SKAction.move(to: destination, duration: 0.05 / Double(CardNode.animationSpeed))

        run(SKAction.sequence([move, bounce1, bounce2])) {
            completion?()
        }
    }

    // MARK: - 탭 애니메이션

    func playTapAnimation() {
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.08)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.08)
        run(SKAction.sequence([scaleUp, scaleDown]))
    }

    // MARK: - 선택 가능 표시

    func setSelectable(_ selectable: Bool) {
        isSelectable = selectable
        if selectable {
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.8, duration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 0.5)
            ])
            run(SKAction.repeatForever(pulse), withKey: "pulse")
        } else {
            removeAction(forKey: "pulse")
            alpha = 1.0
        }
    }
}
