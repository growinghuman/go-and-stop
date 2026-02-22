import UIKit
import SpriteKit

/// 고급 화투 카드 렌더러 - 전통 화투 스타일의 프로그래매틱 렌더링
class CardRenderer {

    // 텍스처 캐시
    private static var textureCache: [String: SKTexture] = [:]
    private static var backTextureCache: SKTexture?

    static func clearCache() {
        textureCache.removeAll()
        backTextureCache = nil
    }

    // MARK: - 카드 앞면

    static func texture(for card: Card) -> SKTexture {
        if let cached = textureCache[card.id] { return cached }

        let size = CGSize(width: 110, height: 160) // 고해상도 렌더링
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let ctx = context.cgContext

            drawCardBase(ctx: ctx, rect: rect, card: card)
            drawCardContent(ctx: ctx, rect: rect, card: card)
            drawCardOverlays(ctx: ctx, rect: rect, card: card)
        }

        let texture = SKTexture(image: image)
        textureCache[card.id] = texture
        return texture
    }

    // MARK: - 카드 뒷면

    static func backTexture() -> SKTexture {
        if let cached = backTextureCache { return cached }

        let size = CGSize(width: 110, height: 160)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let ctx = context.cgContext
            let cr: CGFloat = 8

            // 그림자
            ctx.setShadow(offset: CGSize(width: 1, height: 2), blur: 4,
                          color: UIColor.black.withAlphaComponent(0.4).cgColor)

            // 메인 배경: 진한 빨강
            let bgPath = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: cr)
            UIColor(red: 0.72, green: 0.08, blue: 0.12, alpha: 1).setFill()
            bgPath.fill()

            ctx.setShadow(offset: .zero, blur: 0)

            // 테두리
            UIColor(red: 0.55, green: 0.05, blue: 0.08, alpha: 1).setStroke()
            bgPath.lineWidth = 2
            bgPath.stroke()

            // 내부 프레임
            let inner = rect.insetBy(dx: 10, dy: 14)
            let innerPath = UIBezierPath(roundedRect: inner, cornerRadius: 5)
            UIColor(red: 0.65, green: 0.06, blue: 0.10, alpha: 1).setFill()
            innerPath.fill()
            UIColor(red: 0.80, green: 0.55, blue: 0.10, alpha: 0.6).setStroke()
            innerPath.lineWidth = 1
            innerPath.stroke()

            // 꽃 패턴 (격자형)
            let patternArea = inner.insetBy(dx: 6, dy: 6)
            let cols = 3
            let rows = 4
            let cellW = patternArea.width / CGFloat(cols)
            let cellH = patternArea.height / CGFloat(rows)

            for row in 0..<rows {
                for col in 0..<cols {
                    let cx = patternArea.minX + CGFloat(col) * cellW + cellW / 2
                    let cy = patternArea.minY + CGFloat(row) * cellH + cellH / 2
                    drawMiniFlower(ctx: ctx, center: CGPoint(x: cx, y: cy), radius: 5,
                                   color: UIColor(red: 0.85, green: 0.65, blue: 0.10, alpha: 0.5))
                }
            }

            // 중앙 큰 원
            let centerCircle = CGRect(x: size.width / 2 - 18, y: size.height / 2 - 18, width: 36, height: 36)
            let circlePath = UIBezierPath(ovalIn: centerCircle)
            UIColor(red: 0.85, green: 0.65, blue: 0.10, alpha: 0.7).setFill()
            circlePath.fill()

            // 중앙 花 글자
            let kanji = "花" as NSString
            let kanjiAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor(red: 0.72, green: 0.08, blue: 0.12, alpha: 1)
            ]
            let kanjiSize = kanji.size(withAttributes: kanjiAttrs)
            kanji.draw(at: CGPoint(x: size.width / 2 - kanjiSize.width / 2,
                                   y: size.height / 2 - kanjiSize.height / 2),
                       withAttributes: kanjiAttrs)
        }

        let texture = SKTexture(image: image)
        backTextureCache = texture
        return texture
    }

    // MARK: - 카드 기본 구조

    private static func drawCardBase(ctx: CGContext, rect: CGRect, card: Card) {
        let cr: CGFloat = 8

        // 그림자
        ctx.setShadow(offset: CGSize(width: 1, height: 2), blur: 3,
                      color: UIColor.black.withAlphaComponent(0.35).cgColor)

        // 카드 배경: 아이보리
        let bgPath = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: cr)
        UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1).setFill()
        bgPath.fill()
        ctx.setShadow(offset: .zero, blur: 0)

        // 카드 테두리
        UIColor(red: 0.65, green: 0.55, blue: 0.40, alpha: 1).setStroke()
        bgPath.lineWidth = 1.5
        bgPath.stroke()

        // 상단 배너 (월 표시)
        let bannerHeight: CGFloat = 26
        let bannerRect = CGRect(x: 1.5, y: 1.5, width: rect.width - 3, height: bannerHeight)
        let bannerPath = UIBezierPath(roundedRect: bannerRect,
                                       byRoundingCorners: [.topLeft, .topRight],
                                       cornerRadii: CGSize(width: cr - 1, height: cr - 1))
        monthBannerColor(card).setFill()
        bannerPath.fill()

        // 배너 월 텍스트
        let monthStr = card.month.shortName as NSString
        let monthAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let monthSize = monthStr.size(withAttributes: monthAttrs)
        monthStr.draw(at: CGPoint(x: (rect.width - monthSize.width) / 2,
                                  y: (bannerHeight - monthSize.height) / 2 + 1),
                     withAttributes: monthAttrs)

        // 좌상단 꽃 이름
        let flowerStr = card.month.flower as NSString
        let flowerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        flowerStr.draw(at: CGPoint(x: 6, y: bannerHeight - 11), withAttributes: flowerAttrs)
    }

    // MARK: - 카드 콘텐츠 (월별/타입별 그림)

    private static func drawCardContent(ctx: CGContext, rect: CGRect, card: Card) {
        let contentArea = CGRect(x: 6, y: 30, width: rect.width - 12, height: rect.height - 50)
        let center = CGPoint(x: contentArea.midX, y: contentArea.midY)

        switch card.type {
        case .bright:
            drawBrightContent(ctx: ctx, area: contentArea, center: center, card: card)
        case .animal:
            drawAnimalContent(ctx: ctx, area: contentArea, center: center, card: card)
        case .ribbon:
            drawRibbonContent(ctx: ctx, area: contentArea, center: center, card: card)
        case .junk:
            drawJunkContent(ctx: ctx, area: contentArea, center: center, card: card)
        case .doubleJunk:
            drawDoubleJunkContent(ctx: ctx, area: contentArea, center: center, card: card)
        }
    }

    // MARK: - 광 그리기

    private static func drawBrightContent(ctx: CGContext, area: CGRect, center: CGPoint, card: Card) {
        // 배경 후광
        let glowRadius: CGFloat = 35
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [
                                    UIColor(red: 1, green: 0.9, blue: 0.3, alpha: 0.4).cgColor,
                                    UIColor(red: 1, green: 0.85, blue: 0, alpha: 0).cgColor
                                  ] as CFArray,
                                  locations: [0, 1])!
        ctx.drawRadialGradient(gradient,
                               startCenter: center, startRadius: 0,
                               endCenter: center, endRadius: glowRadius,
                               options: [])

        // 월별 아이콘
        let iconStr: String
        switch card.month {
        case .january:   iconStr = "🏯"   // 학+소나무
        case .march:     iconStr = "🌸"   // 벚꽃 커튼
        case .august:    iconStr = "🌕"   // 보름달
        case .november:  iconStr = "🍂"   // 오동나무
        case .december:  iconStr = "☂️"   // 비
        default:         iconStr = "🌟"
        }

        let iconAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42)
        ]
        let iconSize = (iconStr as NSString).size(withAttributes: iconAttrs)
        (iconStr as NSString).draw(at: CGPoint(x: center.x - iconSize.width / 2,
                                                y: center.y - iconSize.height / 2 - 4),
                                   withAttributes: iconAttrs)

        // 光 마크
        let gwangCircle = CGRect(x: area.maxX - 28, y: area.maxY - 20, width: 24, height: 24)
        ctx.setFillColor(UIColor(red: 0.9, green: 0.15, blue: 0.1, alpha: 1).cgColor)
        ctx.fillEllipse(in: gwangCircle)

        let gwangStr = "光" as NSString
        let gwangAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .black),
            .foregroundColor: UIColor.white
        ]
        let gwangSize = gwangStr.size(withAttributes: gwangAttrs)
        gwangStr.draw(at: CGPoint(x: gwangCircle.midX - gwangSize.width / 2,
                                  y: gwangCircle.midY - gwangSize.height / 2),
                     withAttributes: gwangAttrs)
    }

    // MARK: - 열끗 그리기

    private static func drawAnimalContent(ctx: CGContext, area: CGRect, center: CGPoint, card: Card) {
        let iconStr: String
        switch card.month {
        case .february:  iconStr = "🐤"
        case .april:     iconStr = "🐦"
        case .may:       iconStr = "🌉"
        case .june:      iconStr = "🦋"
        case .july:      iconStr = "🐗"
        case .august:    iconStr = "🦆"
        case .september: iconStr = "🍶"
        case .october:   iconStr = "🦌"
        case .december:  iconStr = "🕊️"
        default:         iconStr = "🐾"
        }

        // 배경: 은은한 원
        ctx.setFillColor(UIColor(red: 0.85, green: 0.93, blue: 0.85, alpha: 0.3).cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - 28, y: center.y - 28, width: 56, height: 56))

        let iconAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 38)
        ]
        let iconSize = (iconStr as NSString).size(withAttributes: iconAttrs)
        (iconStr as NSString).draw(at: CGPoint(x: center.x - iconSize.width / 2,
                                                y: center.y - iconSize.height / 2 - 2),
                                   withAttributes: iconAttrs)

        // 고도리 마크
        if card.isGodoriCard {
            let birdMark = "🐦" as NSString
            let markAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10)
            ]
            birdMark.draw(at: CGPoint(x: area.minX + 2, y: area.maxY - 14), withAttributes: markAttrs)
        }
    }

    // MARK: - 띠 그리기

    private static func drawRibbonContent(ctx: CGContext, area: CGRect, center: CGPoint, card: Card) {
        // 리본 색상
        let ribbonColor: UIColor
        let ribbonText: String
        switch card.ribbonType {
        case .redPoetry:
            ribbonColor = UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1)
            ribbonText = "홍단"
        case .bluePlain:
            ribbonColor = UIColor(red: 0.15, green: 0.3, blue: 0.7, alpha: 1)
            ribbonText = "청단"
        case .redPlain:
            ribbonColor = UIColor(red: 0.9, green: 0.35, blue: 0.15, alpha: 1)
            ribbonText = "초단"
        case .none:
            ribbonColor = .gray
            ribbonText = "띠"
        }

        // 물결 리본
        let ribbonPath = UIBezierPath()
        let rY = center.y - 5
        let rW: CGFloat = area.width - 16
        let startX = area.minX + 8

        ribbonPath.move(to: CGPoint(x: startX, y: rY - 12))
        ribbonPath.addCurve(to: CGPoint(x: startX + rW, y: rY - 12),
                            controlPoint1: CGPoint(x: startX + rW * 0.3, y: rY - 24),
                            controlPoint2: CGPoint(x: startX + rW * 0.7, y: rY))
        ribbonPath.addLine(to: CGPoint(x: startX + rW, y: rY + 12))
        ribbonPath.addCurve(to: CGPoint(x: startX, y: rY + 12),
                            controlPoint1: CGPoint(x: startX + rW * 0.7, y: rY + 24),
                            controlPoint2: CGPoint(x: startX + rW * 0.3, y: rY))
        ribbonPath.close()

        ribbonColor.setFill()
        ribbonPath.fill()

        // 리본 위에 글자 (홍단만)
        if card.ribbonType == .redPoetry {
            let text = card.month.flower as NSString
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: textAttrs)
            text.draw(at: CGPoint(x: center.x - textSize.width / 2,
                                  y: rY - textSize.height / 2),
                     withAttributes: textAttrs)
        }

        // 배경 꽃 장식
        let flowerEmoji = monthFlowerEmoji(card.month) as NSString
        let flowerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22)
        ]
        let flowerSize = flowerEmoji.size(withAttributes: flowerAttrs)
        flowerEmoji.draw(at: CGPoint(x: center.x - flowerSize.width / 2,
                                     y: area.minY + 4),
                        withAttributes: flowerAttrs)
    }

    // MARK: - 피 그리기

    private static func drawJunkContent(ctx: CGContext, area: CGRect, center: CGPoint, card: Card) {
        // 배경 꽃
        let flowerEmoji = monthFlowerEmoji(card.month) as NSString
        let flowerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32)
        ]
        let flowerSize = flowerEmoji.size(withAttributes: flowerAttrs)
        flowerEmoji.draw(at: CGPoint(x: center.x - flowerSize.width / 2,
                                     y: center.y - flowerSize.height / 2 - 2),
                        withAttributes: flowerAttrs)

        // 작은 꽃잎 장식
        for i in 0..<3 {
            let angle = CGFloat(i) * 2.1 + 0.5
            let r: CGFloat = 25
            let px = center.x + cos(angle) * r
            let py = center.y + sin(angle) * r
            drawMiniFlower(ctx: ctx, center: CGPoint(x: px, y: py), radius: 3,
                           color: monthAccentColor(card.month).withAlphaComponent(0.4))
        }
    }

    private static func drawDoubleJunkContent(ctx: CGContext, area: CGRect, center: CGPoint, card: Card) {
        let flowerEmoji = monthFlowerEmoji(card.month) as NSString
        let flowerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26)
        ]
        let flowerSize = flowerEmoji.size(withAttributes: flowerAttrs)
        // 두 개
        flowerEmoji.draw(at: CGPoint(x: center.x - flowerSize.width / 2 - 10,
                                     y: center.y - flowerSize.height / 2 - 6),
                        withAttributes: flowerAttrs)
        flowerEmoji.draw(at: CGPoint(x: center.x - flowerSize.width / 2 + 10,
                                     y: center.y - flowerSize.height / 2 + 6),
                        withAttributes: flowerAttrs)

        // 쌍피 마크
        let markRect = CGRect(x: area.maxX - 22, y: area.maxY - 16, width: 18, height: 14)
        UIColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 0.8).setFill()
        UIBezierPath(roundedRect: markRect, cornerRadius: 3).fill()
        let markStr = "×2" as NSString
        let markAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        markStr.draw(at: CGPoint(x: markRect.minX + 2, y: markRect.minY + 1), withAttributes: markAttrs)
    }

    // MARK: - 오버레이

    private static func drawCardOverlays(ctx: CGContext, rect: CGRect, card: Card) {
        // 하단 타입 표시
        let bottomY = rect.height - 18
        let typeStr = card.type.displayName as NSString
        let typeColor = cardTypeAccentColor(card.type)
        let typeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: typeColor
        ]
        let typeSize = typeStr.size(withAttributes: typeAttrs)
        typeStr.draw(at: CGPoint(x: (rect.width - typeSize.width) / 2, y: bottomY),
                    withAttributes: typeAttrs)
    }

    // MARK: - 색상 헬퍼

    private static func monthBannerColor(_ card: Card) -> UIColor {
        switch card.type {
        case .bright:     return UIColor(red: 0.80, green: 0.58, blue: 0.0, alpha: 1)
        case .animal:     return UIColor(red: 0.18, green: 0.52, blue: 0.22, alpha: 1)
        case .ribbon:
            switch card.ribbonType {
            case .redPoetry: return UIColor(red: 0.75, green: 0.12, blue: 0.15, alpha: 1)
            case .bluePlain: return UIColor(red: 0.15, green: 0.25, blue: 0.60, alpha: 1)
            case .redPlain:  return UIColor(red: 0.80, green: 0.30, blue: 0.12, alpha: 1)
            case .none:      return UIColor.gray
            }
        case .junk:       return UIColor(red: 0.45, green: 0.42, blue: 0.38, alpha: 1)
        case .doubleJunk: return UIColor(red: 0.35, green: 0.55, blue: 0.35, alpha: 1)
        }
    }

    private static func cardTypeAccentColor(_ type: CardType) -> UIColor {
        switch type {
        case .bright:     return UIColor(red: 0.80, green: 0.60, blue: 0, alpha: 1)
        case .animal:     return UIColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1)
        case .ribbon:     return UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1)
        case .junk:       return UIColor(red: 0.5, green: 0.45, blue: 0.4, alpha: 1)
        case .doubleJunk: return UIColor(red: 0.3, green: 0.55, blue: 0.3, alpha: 1)
        }
    }

    private static func monthAccentColor(_ month: CardMonth) -> UIColor {
        switch month {
        case .january:   return UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1)
        case .february:  return UIColor(red: 0.85, green: 0.3, blue: 0.4, alpha: 1)
        case .march:     return UIColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 1)
        case .april:     return UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        case .may:       return UIColor(red: 0.4, green: 0.7, blue: 0.3, alpha: 1)
        case .june:      return UIColor(red: 0.8, green: 0.2, blue: 0.4, alpha: 1)
        case .july:      return UIColor(red: 0.7, green: 0.3, blue: 0.2, alpha: 1)
        case .august:    return UIColor(red: 0.6, green: 0.7, blue: 0.5, alpha: 1)
        case .september: return UIColor(red: 0.7, green: 0.5, blue: 0.8, alpha: 1)
        case .october:   return UIColor(red: 0.9, green: 0.4, blue: 0.15, alpha: 1)
        case .november:  return UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1)
        case .december:  return UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1)
        }
    }

    private static func monthFlowerEmoji(_ month: CardMonth) -> String {
        switch month {
        case .january:   return "🌲"
        case .february:  return "🌺"
        case .march:     return "🌸"
        case .april:     return "🌿"
        case .may:       return "🌷"
        case .june:      return "🌹"
        case .july:      return "🍀"
        case .august:    return "🌾"
        case .september: return "🏵️"
        case .october:   return "🍁"
        case .november:  return "🍂"
        case .december:  return "🌧️"
        }
    }

    // MARK: - 미니 꽃 그리기

    private static func drawMiniFlower(ctx: CGContext, center: CGPoint, radius: CGFloat, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        let petals = 5
        for i in 0..<petals {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(petals)) - .pi / 2
            let px = center.x + cos(angle) * radius
            let py = center.y + sin(angle) * radius
            ctx.fillEllipse(in: CGRect(x: px - radius * 0.6, y: py - radius * 0.6,
                                       width: radius * 1.2, height: radius * 1.2))
        }
        // 중심
        ctx.setFillColor(UIColor.yellow.withAlphaComponent(0.6).cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - radius * 0.4, y: center.y - radius * 0.4,
                                   width: radius * 0.8, height: radius * 0.8))
    }
}
