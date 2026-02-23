import UIKit
import SpriteKit

/// 한국 전통 화투 스타일 카드 렌더러 - CoreGraphics 기반
class CardRenderer {

    private static var textureCache: [String: SKTexture] = [:]
    private static var backTextureCache: SKTexture?

    static func clearCache() {
        textureCache.removeAll()
        backTextureCache = nil
    }

    // MARK: - 카드 앞면

    static func texture(for card: Card) -> SKTexture {
        if let cached = textureCache[card.id] { return cached }

        let size = CGSize(width: 110, height: 160)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let ctx = context.cgContext
            drawCardFront(ctx: ctx, rect: rect, card: card)
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
            drawCardBack(ctx: ctx, rect: rect)
        }

        let texture = SKTexture(image: image)
        backTextureCache = texture
        return texture
    }

    // MARK: - 앞면 전체 그리기

    private static func drawCardFront(ctx: CGContext, rect: CGRect, card: Card) {
        let cr: CGFloat = 8

        // 그림자
        ctx.setShadow(offset: CGSize(width: 1, height: 2), blur: 3,
                      color: UIColor.black.withAlphaComponent(0.35).cgColor)

        // 카드 배경
        let bgPath = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: cr)
        UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1).setFill()
        bgPath.fill()
        ctx.setShadow(offset: .zero, blur: 0)

        // 빨간 테두리 (전통 화투 느낌)
        UIColor(red: 0.72, green: 0.10, blue: 0.10, alpha: 1).setStroke()
        bgPath.lineWidth = 2.5
        bgPath.stroke()

        // 내부 여백선
        let innerRect = rect.insetBy(dx: 5, dy: 5)
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: cr - 2)
        UIColor(red: 0.72, green: 0.10, blue: 0.10, alpha: 0.15).setStroke()
        innerPath.lineWidth = 0.5
        innerPath.stroke()

        // 월별 배경 식물 그리기
        let contentArea = CGRect(x: 8, y: 8, width: rect.width - 16, height: rect.height - 16)
        drawMonthPlant(ctx: ctx, area: contentArea, card: card)

        // 타입별 오버레이
        drawTypeOverlay(ctx: ctx, rect: rect, card: card)

        // 월 번호 표시
        drawMonthBadge(ctx: ctx, rect: rect, card: card)
    }

    // MARK: - 뒷면 그리기

    private static func drawCardBack(ctx: CGContext, rect: CGRect) {
        let cr: CGFloat = 8

        ctx.setShadow(offset: CGSize(width: 1, height: 2), blur: 4,
                      color: UIColor.black.withAlphaComponent(0.4).cgColor)

        // 진한 빨강 배경
        let bgPath = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: cr)
        UIColor(red: 0.72, green: 0.08, blue: 0.12, alpha: 1).setFill()
        bgPath.fill()
        ctx.setShadow(offset: .zero, blur: 0)

        // 테두리
        UIColor(red: 0.55, green: 0.05, blue: 0.08, alpha: 1).setStroke()
        bgPath.lineWidth = 2
        bgPath.stroke()

        // 금색 내부 프레임
        let inner = rect.insetBy(dx: 10, dy: 14)
        let innerPath = UIBezierPath(roundedRect: inner, cornerRadius: 5)
        UIColor(red: 0.65, green: 0.06, blue: 0.10, alpha: 1).setFill()
        innerPath.fill()
        UIColor(red: 0.82, green: 0.62, blue: 0.12, alpha: 0.7).setStroke()
        innerPath.lineWidth = 1.5
        innerPath.stroke()

        // 꽃 패턴 격자
        let patternArea = inner.insetBy(dx: 6, dy: 6)
        let cols = 3, rows = 4
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

        // 중앙 금색 원 + 花
        let centerCircle = CGRect(x: rect.width / 2 - 18, y: rect.height / 2 - 18, width: 36, height: 36)
        UIColor(red: 0.85, green: 0.65, blue: 0.10, alpha: 0.8).setFill()
        UIBezierPath(ovalIn: centerCircle).fill()

        let kanji = "花" as NSString
        let kanjiAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor(red: 0.72, green: 0.08, blue: 0.12, alpha: 1)
        ]
        let kanjiSize = kanji.size(withAttributes: kanjiAttrs)
        kanji.draw(at: CGPoint(x: rect.width / 2 - kanjiSize.width / 2,
                               y: rect.height / 2 - kanjiSize.height / 2),
                   withAttributes: kanjiAttrs)
    }

    // MARK: - 월 번호 뱃지

    private static func drawMonthBadge(ctx: CGContext, rect: CGRect, card: Card) {
        // 좌상단 원형 뱃지
        let badgeSize: CGFloat = 22
        let badgeRect = CGRect(x: 8, y: 8, width: badgeSize, height: badgeSize)

        // 배경 원
        ctx.setFillColor(UIColor(red: 0.72, green: 0.10, blue: 0.10, alpha: 0.9).cgColor)
        ctx.fillEllipse(in: badgeRect)

        // 월 숫자
        let numStr = "\(card.month.rawValue)" as NSString
        let numAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: card.month.rawValue >= 10 ? 10 : 12, weight: .black),
            .foregroundColor: UIColor.white
        ]
        let numSize = numStr.size(withAttributes: numAttrs)
        numStr.draw(at: CGPoint(x: badgeRect.midX - numSize.width / 2,
                                y: badgeRect.midY - numSize.height / 2),
                   withAttributes: numAttrs)
    }

    // MARK: - 타입별 오버레이

    private static func drawTypeOverlay(ctx: CGContext, rect: CGRect, card: Card) {
        switch card.type {
        case .bright:
            drawBrightMark(ctx: ctx, rect: rect, card: card)
        case .animal:
            drawAnimalMark(ctx: ctx, rect: rect, card: card)
        case .ribbon:
            drawRibbonOverlay(ctx: ctx, rect: rect, card: card)
        case .junk:
            drawJunkMark(ctx: ctx, rect: rect)
        case .doubleJunk:
            drawDoubleJunkMark(ctx: ctx, rect: rect)
        }
    }

    // MARK: - 光 마크 (광)

    private static func drawBrightMark(ctx: CGContext, rect: CGRect, card: Card) {
        // 우하단 큰 光 마크
        let circleSize: CGFloat = 28
        let cx = rect.width - circleSize - 6
        let cy = rect.height - circleSize - 6
        let circleRect = CGRect(x: cx, y: cy, width: circleSize, height: circleSize)

        // 빨간 원
        ctx.setFillColor(UIColor(red: 0.85, green: 0.12, blue: 0.10, alpha: 1).cgColor)
        ctx.fillEllipse(in: circleRect)
        // 금색 테두리
        ctx.setStrokeColor(UIColor(red: 0.85, green: 0.65, blue: 0.10, alpha: 1).cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: circleRect)

        let gwangStr = "光" as NSString
        let gwangAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .black),
            .foregroundColor: UIColor(red: 1, green: 0.92, blue: 0.4, alpha: 1)
        ]
        let gwangSize = gwangStr.size(withAttributes: gwangAttrs)
        gwangStr.draw(at: CGPoint(x: circleRect.midX - gwangSize.width / 2,
                                  y: circleRect.midY - gwangSize.height / 2),
                     withAttributes: gwangAttrs)

        // 후광 효과
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: [
                                        UIColor(red: 1, green: 0.9, blue: 0.3, alpha: 0.25).cgColor,
                                        UIColor(red: 1, green: 0.85, blue: 0, alpha: 0).cgColor
                                     ] as CFArray,
                                     locations: [0, 1]) {
            let center = CGPoint(x: circleRect.midX, y: circleRect.midY)
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: circleSize / 2,
                                   endCenter: center, endRadius: circleSize,
                                   options: [])
        }
    }

    // MARK: - 열끗 마크

    private static func drawAnimalMark(ctx: CGContext, rect: CGRect, card: Card) {
        // 우하단 동물 표시
        let markRect = CGRect(x: rect.width - 28, y: rect.height - 20, width: 22, height: 14)
        UIColor(red: 0.18, green: 0.50, blue: 0.22, alpha: 0.85).setFill()
        UIBezierPath(roundedRect: markRect, cornerRadius: 3).fill()

        let label = "열" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let labelSize = label.size(withAttributes: attrs)
        label.draw(at: CGPoint(x: markRect.midX - labelSize.width / 2,
                               y: markRect.midY - labelSize.height / 2),
                  withAttributes: attrs)

        // 고도리 마크
        if card.isGodoriCard {
            let godoriRect = CGRect(x: rect.width - 28, y: rect.height - 36, width: 22, height: 14)
            UIColor(red: 0.85, green: 0.55, blue: 0.10, alpha: 0.9).setFill()
            UIBezierPath(roundedRect: godoriRect, cornerRadius: 3).fill()
            let gLabel = "鳥" as NSString
            let gAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let gSize = gLabel.size(withAttributes: gAttrs)
            gLabel.draw(at: CGPoint(x: godoriRect.midX - gSize.width / 2,
                                    y: godoriRect.midY - gSize.height / 2),
                       withAttributes: gAttrs)
        }
    }

    // MARK: - 띠 오버레이

    private static func drawRibbonOverlay(ctx: CGContext, rect: CGRect, card: Card) {
        let ribbonColor: UIColor
        let ribbonText: String?

        switch card.ribbonType {
        case .redPoetry:
            ribbonColor = UIColor(red: 0.82, green: 0.12, blue: 0.15, alpha: 1)
            ribbonText = card.month.flower
        case .bluePlain:
            ribbonColor = UIColor(red: 0.12, green: 0.25, blue: 0.65, alpha: 1)
            ribbonText = nil
        case .redPlain:
            ribbonColor = UIColor(red: 0.85, green: 0.30, blue: 0.12, alpha: 1)
            ribbonText = nil
        case .none:
            ribbonColor = .gray
            ribbonText = nil
        }

        // 물결 리본 (가로, 카드 중앙)
        let rY = rect.height * 0.52
        let rW = rect.width - 20
        let startX: CGFloat = 10

        let ribbonPath = UIBezierPath()
        ribbonPath.move(to: CGPoint(x: startX, y: rY - 10))
        ribbonPath.addCurve(to: CGPoint(x: startX + rW, y: rY - 10),
                            controlPoint1: CGPoint(x: startX + rW * 0.3, y: rY - 22),
                            controlPoint2: CGPoint(x: startX + rW * 0.7, y: rY + 2))
        ribbonPath.addLine(to: CGPoint(x: startX + rW, y: rY + 10))
        ribbonPath.addCurve(to: CGPoint(x: startX, y: rY + 10),
                            controlPoint1: CGPoint(x: startX + rW * 0.7, y: rY + 22),
                            controlPoint2: CGPoint(x: startX + rW * 0.3, y: rY - 2))
        ribbonPath.close()

        ribbonColor.setFill()
        ribbonPath.fill()

        // 리본 테두리
        ribbonColor.withAlphaComponent(0.5).setStroke()
        ribbonPath.lineWidth = 0.5
        ribbonPath.stroke()

        // 홍단 텍스트 (리본 위에)
        if let text = ribbonText {
            let textStr = text as NSString
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8, weight: .bold),
                .foregroundColor: UIColor(red: 1, green: 0.9, blue: 0.7, alpha: 1)
            ]
            let textSize = textStr.size(withAttributes: textAttrs)
            textStr.draw(at: CGPoint(x: rect.width / 2 - textSize.width / 2,
                                     y: rY - textSize.height / 2),
                        withAttributes: textAttrs)
        }

        // 하단 타입 표시
        let markRect = CGRect(x: rect.width - 26, y: rect.height - 18, width: 20, height: 12)
        ribbonColor.withAlphaComponent(0.85).setFill()
        UIBezierPath(roundedRect: markRect, cornerRadius: 2).fill()
        let label = "띠" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let labelSize = label.size(withAttributes: attrs)
        label.draw(at: CGPoint(x: markRect.midX - labelSize.width / 2,
                               y: markRect.midY - labelSize.height / 2),
                  withAttributes: attrs)
    }

    // MARK: - 피 마크

    private static func drawJunkMark(ctx: CGContext, rect: CGRect) {
        // 우하단 작은 점
        let dotRect = CGRect(x: rect.width - 16, y: rect.height - 16, width: 10, height: 10)
        UIColor(red: 0.5, green: 0.45, blue: 0.38, alpha: 0.6).setFill()
        UIBezierPath(ovalIn: dotRect).fill()
    }

    private static func drawDoubleJunkMark(ctx: CGContext, rect: CGRect) {
        // 쌍피: ×2 뱃지
        let markRect = CGRect(x: rect.width - 28, y: rect.height - 20, width: 22, height: 14)
        UIColor(red: 0.30, green: 0.55, blue: 0.30, alpha: 0.9).setFill()
        UIBezierPath(roundedRect: markRect, cornerRadius: 3).fill()
        let label = "×2" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let labelSize = label.size(withAttributes: attrs)
        label.draw(at: CGPoint(x: markRect.midX - labelSize.width / 2,
                               y: markRect.midY - labelSize.height / 2),
                  withAttributes: attrs)
    }

    // MARK: - 월별 식물 그리기 (한국 화투 스타일)

    private static func drawMonthPlant(ctx: CGContext, area: CGRect, card: Card) {
        let center = CGPoint(x: area.midX, y: area.midY)

        switch card.month {
        case .january:   drawPine(ctx: ctx, area: area, card: card)
        case .february:  drawPlumBlossom(ctx: ctx, area: area, card: card)
        case .march:     drawCherryBlossom(ctx: ctx, area: area, card: card)
        case .april:     drawWisteria(ctx: ctx, area: area, card: card)
        case .may:       drawOrchid(ctx: ctx, area: area, card: card)
        case .june:      drawPeony(ctx: ctx, area: area, card: card)
        case .july:      drawBushClover(ctx: ctx, area: area, card: card)
        case .august:    drawPampasGrass(ctx: ctx, area: area, card: card)
        case .september: drawChrysanthemum(ctx: ctx, area: area, card: card)
        case .october:   drawMaple(ctx: ctx, area: area, card: card)
        case .november:  drawPaulownia(ctx: ctx, area: area, card: card)
        case .december:  drawWillow(ctx: ctx, area: area, card: card)
        }
    }

    // MARK: - 1월 소나무 (松)

    private static func drawPine(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 소나무 줄기
        ctx.setStrokeColor(UIColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 1).cgColor)
        ctx.setLineWidth(4)
        ctx.move(to: CGPoint(x: cx, y: area.maxY - 10))
        ctx.addLine(to: CGPoint(x: cx - 3, y: cy + 5))
        ctx.strokePath()

        // 소나무 잎 (둥근 초록 뭉치들)
        let pineGreen = UIColor(red: 0.10, green: 0.38, blue: 0.18, alpha: 1)
        let pineLight = UIColor(red: 0.18, green: 0.52, blue: 0.22, alpha: 1)

        // 큰 잎 뭉치
        drawOvalClump(ctx: ctx, center: CGPoint(x: cx - 12, y: cy - 5), rx: 18, ry: 14, color: pineGreen)
        drawOvalClump(ctx: ctx, center: CGPoint(x: cx + 10, y: cy - 12), rx: 16, ry: 12, color: pineLight)
        drawOvalClump(ctx: ctx, center: CGPoint(x: cx - 2, y: cy - 22), rx: 14, ry: 10, color: pineGreen)

        // 광: 학 (두루미)
        if card.type == .bright {
            drawCrane(ctx: ctx, area: area)
        }
    }

    private static func drawCrane(ctx: CGContext, area: CGRect) {
        let cx = area.midX + 5, cy = area.midY + 18

        // 몸통 (흰색 타원)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 12, y: cy - 6, width: 24, height: 12))

        // 목 (흰색 곡선)
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: cx - 6, y: cy - 4))
        ctx.addQuadCurve(to: CGPoint(x: cx - 14, y: cy - 22), control: CGPoint(x: cx - 18, y: cy - 10))
        ctx.strokePath()

        // 머리 (빨간 점)
        ctx.setFillColor(UIColor(red: 0.9, green: 0.15, blue: 0.10, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 17, y: cy - 25, width: 7, height: 7))

        // 부리
        ctx.setStrokeColor(UIColor(red: 0.3, green: 0.3, blue: 0.0, alpha: 1).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx - 18, y: cy - 22))
        ctx.addLine(to: CGPoint(x: cx - 24, y: cy - 20))
        ctx.strokePath()

        // 꼬리 (검은 깃털)
        ctx.setFillColor(UIColor.black.cgColor)
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: cx + 10, y: cy - 2))
        tailPath.addCurve(to: CGPoint(x: cx + 22, y: cy - 10),
                          controlPoint1: CGPoint(x: cx + 16, y: cy - 2),
                          controlPoint2: CGPoint(x: cx + 20, y: cy - 6))
        tailPath.addCurve(to: CGPoint(x: cx + 10, y: cy + 2),
                          controlPoint1: CGPoint(x: cx + 18, y: cy - 4),
                          controlPoint2: CGPoint(x: cx + 14, y: cy))
        tailPath.close()
        tailPath.fill()
    }

    // MARK: - 2월 매화 (梅)

    private static func drawPlumBlossom(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 가지
        ctx.setStrokeColor(UIColor(red: 0.30, green: 0.18, blue: 0.08, alpha: 1).cgColor)
        ctx.setLineWidth(2.5)
        ctx.move(to: CGPoint(x: area.minX + 5, y: area.maxY - 5))
        ctx.addQuadCurve(to: CGPoint(x: cx + 15, y: cy - 20),
                         control: CGPoint(x: cx - 10, y: cy + 10))
        ctx.strokePath()

        // 작은 가지
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx - 5, y: cy + 5))
        ctx.addLine(to: CGPoint(x: cx + 20, y: cy + 15))
        ctx.strokePath()

        // 매화 꽃들 (빨간/분홍 5잎 꽃)
        let plumRed = UIColor(red: 0.85, green: 0.15, blue: 0.25, alpha: 1)
        let plumPink = UIColor(red: 0.95, green: 0.40, blue: 0.50, alpha: 1)

        drawFlower5(ctx: ctx, center: CGPoint(x: cx - 5, y: cy - 10), radius: 8, color: plumRed)
        drawFlower5(ctx: ctx, center: CGPoint(x: cx + 15, y: cy - 18), radius: 7, color: plumPink)
        drawFlower5(ctx: ctx, center: CGPoint(x: cx + 8, y: cy + 5), radius: 6, color: plumRed)

        if card.type == .bright || card.type == .animal {
            drawFlower5(ctx: ctx, center: CGPoint(x: cx - 15, y: cy - 22), radius: 5, color: plumPink)
        }

        // 열끗: 꾀꼬리
        if card.type == .animal {
            drawSmallBird(ctx: ctx, center: CGPoint(x: cx + 5, y: cy + 20),
                         bodyColor: UIColor(red: 0.75, green: 0.70, blue: 0.10, alpha: 1))
        }
    }

    // MARK: - 3월 벚꽃 (桜)

    private static func drawCherryBlossom(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 벚꽃 구름 (겹겹이 분홍)
        let sakuraPink = UIColor(red: 1.0, green: 0.72, blue: 0.78, alpha: 0.9)
        let sakuraDeep = UIColor(red: 0.95, green: 0.55, blue: 0.65, alpha: 0.85)

        drawOvalClump(ctx: ctx, center: CGPoint(x: cx - 8, y: cy - 18), rx: 22, ry: 14, color: sakuraPink)
        drawOvalClump(ctx: ctx, center: CGPoint(x: cx + 12, y: cy - 12), rx: 18, ry: 12, color: sakuraDeep)
        drawOvalClump(ctx: ctx, center: CGPoint(x: cx, y: cy - 8), rx: 20, ry: 14, color: sakuraPink)

        // 꽃잎 디테일
        drawFlower5(ctx: ctx, center: CGPoint(x: cx - 10, y: cy - 15), radius: 5, color: sakuraDeep)
        drawFlower5(ctx: ctx, center: CGPoint(x: cx + 8, y: cy - 8), radius: 4, color: UIColor(red: 1, green: 0.85, blue: 0.88, alpha: 1))

        // 광: 커튼 (만막)
        if card.type == .bright {
            drawCurtain(ctx: ctx, area: area)
        }
    }

    private static func drawCurtain(ctx: CGContext, area: CGRect) {
        // 빨간 커튼 (하단에서 내려옴)
        let curtainPath = UIBezierPath()
        let cTop = area.midY + 5
        let cBottom = area.maxY - 8
        let cLeft = area.minX + 5
        let cRight = area.maxX - 5

        curtainPath.move(to: CGPoint(x: cLeft, y: cTop))
        curtainPath.addLine(to: CGPoint(x: cRight, y: cTop))
        curtainPath.addLine(to: CGPoint(x: cRight, y: cBottom))
        // 물결 아래쪽
        curtainPath.addCurve(to: CGPoint(x: cLeft, y: cBottom),
                             controlPoint1: CGPoint(x: cRight - 20, y: cBottom + 8),
                             controlPoint2: CGPoint(x: cLeft + 20, y: cBottom - 8))
        curtainPath.close()

        UIColor(red: 0.82, green: 0.12, blue: 0.18, alpha: 0.85).setFill()
        curtainPath.fill()

        // 커튼 줄
        ctx.setStrokeColor(UIColor(red: 0.65, green: 0.08, blue: 0.12, alpha: 0.6).cgColor)
        ctx.setLineWidth(1)
        for i in stride(from: cLeft + 8, to: cRight - 5, by: 10) {
            ctx.move(to: CGPoint(x: i, y: cTop))
            ctx.addLine(to: CGPoint(x: i + 2, y: cBottom - 3))
            ctx.strokePath()
        }

        // 커튼 상단 가로바
        ctx.setFillColor(UIColor(red: 0.65, green: 0.08, blue: 0.12, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cLeft, y: cTop - 3, width: cRight - cLeft, height: 6))
    }

    // MARK: - 4월 흑싸리 (등나무)

    private static func drawWisteria(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 줄기
        ctx.setStrokeColor(UIColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 1).cgColor)
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: cx - 15, y: area.minY + 8))
        ctx.addQuadCurve(to: CGPoint(x: cx + 5, y: area.maxY - 15),
                         control: CGPoint(x: cx + 10, y: cy))
        ctx.strokePath()

        // 검은 잎들
        let darkGreen = UIColor(red: 0.12, green: 0.18, blue: 0.10, alpha: 0.8)
        for i in 0..<5 {
            let py = area.minY + 20 + CGFloat(i) * 18
            let px = cx - 10 + CGFloat(i % 2) * 12
            drawLeaf(ctx: ctx, center: CGPoint(x: px, y: py), length: 12, angle: CGFloat(i) * 0.3 - 0.3, color: darkGreen)
        }

        // 열끗: 두견새
        if card.type == .animal {
            drawSmallBird(ctx: ctx, center: CGPoint(x: cx + 15, y: cy + 10),
                         bodyColor: UIColor(red: 0.5, green: 0.35, blue: 0.25, alpha: 1))
        }
    }

    // MARK: - 5월 난초 (蘭)

    private static func drawOrchid(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 긴 잎
        let orchidGreen = UIColor(red: 0.20, green: 0.50, blue: 0.18, alpha: 1)
        ctx.setStrokeColor(orchidGreen.cgColor)
        ctx.setLineWidth(2.5)
        ctx.setLineCap(.round)

        // 잎 1 (왼쪽 휜)
        ctx.move(to: CGPoint(x: cx, y: area.maxY - 10))
        ctx.addQuadCurve(to: CGPoint(x: cx - 25, y: cy - 20), control: CGPoint(x: cx - 15, y: cy + 5))
        ctx.strokePath()

        // 잎 2 (오른쪽 휜)
        ctx.move(to: CGPoint(x: cx + 2, y: area.maxY - 12))
        ctx.addQuadCurve(to: CGPoint(x: cx + 22, y: cy - 15), control: CGPoint(x: cx + 12, y: cy + 8))
        ctx.strokePath()

        // 잎 3 (중앙)
        ctx.move(to: CGPoint(x: cx - 1, y: area.maxY - 8))
        ctx.addQuadCurve(to: CGPoint(x: cx + 3, y: cy - 25), control: CGPoint(x: cx + 5, y: cy))
        ctx.strokePath()

        // 열끗: 다리
        if card.type == .animal {
            // 팔각 다리
            ctx.setFillColor(UIColor(red: 0.60, green: 0.45, blue: 0.25, alpha: 0.8).cgColor)
            ctx.fill(CGRect(x: area.minX + 8, y: area.maxY - 22, width: area.width - 16, height: 4))
            // 다리 기둥
            ctx.fill(CGRect(x: area.minX + 15, y: area.maxY - 22, width: 3, height: 14))
            ctx.fill(CGRect(x: area.maxX - 18, y: area.maxY - 22, width: 3, height: 14))
        }
    }

    // MARK: - 6월 목단 (牡丹)

    private static func drawPeony(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY - 5

        // 큰 꽃 (겹꽃잎)
        let peonyRed = UIColor(red: 0.85, green: 0.15, blue: 0.30, alpha: 1)
        let peonyPink = UIColor(red: 0.95, green: 0.35, blue: 0.50, alpha: 0.9)
        let peonyLight = UIColor(red: 1.0, green: 0.55, blue: 0.65, alpha: 0.85)

        // 외곽 꽃잎
        drawFlower5(ctx: ctx, center: CGPoint(x: cx, y: cy), radius: 18, color: peonyRed)
        drawFlower5(ctx: ctx, center: CGPoint(x: cx, y: cy), radius: 13, color: peonyPink)
        drawFlower5(ctx: ctx, center: CGPoint(x: cx + 2, y: cy - 2), radius: 8, color: peonyLight)

        // 중심
        ctx.setFillColor(UIColor(red: 0.90, green: 0.80, blue: 0.20, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 3, y: cy - 3, width: 6, height: 6))

        // 잎
        let leafGreen = UIColor(red: 0.15, green: 0.45, blue: 0.18, alpha: 0.8)
        drawLeaf(ctx: ctx, center: CGPoint(x: cx - 20, y: cy + 15), length: 14, angle: -0.5, color: leafGreen)
        drawLeaf(ctx: ctx, center: CGPoint(x: cx + 18, y: cy + 12), length: 12, angle: 0.6, color: leafGreen)

        // 열끗: 나비
        if card.type == .animal {
            drawButterfly(ctx: ctx, center: CGPoint(x: cx + 15, y: cy - 20))
        }
    }

    private static func drawButterfly(ctx: CGContext, center: CGPoint) {
        let cx = center.x, cy = center.y

        // 왼쪽 날개
        ctx.setFillColor(UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 0.85).cgColor)
        let leftWing = UIBezierPath()
        leftWing.move(to: CGPoint(x: cx, y: cy))
        leftWing.addQuadCurve(to: CGPoint(x: cx - 10, y: cy - 6),
                              control: CGPoint(x: cx - 8, y: cy - 10))
        leftWing.addQuadCurve(to: CGPoint(x: cx, y: cy),
                              control: CGPoint(x: cx - 8, y: cy + 2))
        leftWing.fill()

        // 오른쪽 날개
        let rightWing = UIBezierPath()
        rightWing.move(to: CGPoint(x: cx, y: cy))
        rightWing.addQuadCurve(to: CGPoint(x: cx + 10, y: cy - 6),
                               control: CGPoint(x: cx + 8, y: cy - 10))
        rightWing.addQuadCurve(to: CGPoint(x: cx, y: cy),
                               control: CGPoint(x: cx + 8, y: cy + 2))
        rightWing.fill()

        // 몸통
        ctx.setFillColor(UIColor(red: 0.3, green: 0.2, blue: 0.0, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 1, y: cy - 4, width: 2, height: 8))
    }

    // MARK: - 7월 홍싸리

    private static func drawBushClover(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 줄기
        ctx.setStrokeColor(UIColor(red: 0.35, green: 0.25, blue: 0.12, alpha: 1).cgColor)
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: cx, y: area.maxY - 8))
        ctx.addQuadCurve(to: CGPoint(x: cx - 5, y: cy - 15), control: CGPoint(x: cx + 5, y: cy))
        ctx.strokePath()

        // 빨간 작은 잎/꽃
        let cloverRed = UIColor(red: 0.80, green: 0.20, blue: 0.15, alpha: 0.9)
        let cloverOrange = UIColor(red: 0.85, green: 0.40, blue: 0.15, alpha: 0.85)

        // 좌측 가지
        ctx.setStrokeColor(UIColor(red: 0.35, green: 0.25, blue: 0.12, alpha: 0.8).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx - 3, y: cy))
        ctx.addQuadCurve(to: CGPoint(x: cx - 25, y: cy - 10), control: CGPoint(x: cx - 15, y: cy - 15))
        ctx.strokePath()

        // 우측 가지
        ctx.move(to: CGPoint(x: cx + 2, y: cy - 5))
        ctx.addQuadCurve(to: CGPoint(x: cx + 22, y: cy - 18), control: CGPoint(x: cx + 15, y: cy - 5))
        ctx.strokePath()

        // 잎들
        for i in 0..<4 {
            let angle = CGFloat(i) * 0.8 - 1.2
            let r: CGFloat = 12 + CGFloat(i) * 4
            let px = cx + cos(angle) * r - 5
            let py = cy - 5 + sin(angle) * r * 0.5
            drawOvalClump(ctx: ctx, center: CGPoint(x: px, y: py), rx: 5, ry: 3,
                         color: i % 2 == 0 ? cloverRed : cloverOrange)
        }

        // 열끗: 멧돼지
        if card.type == .animal {
            drawBoar(ctx: ctx, center: CGPoint(x: cx, y: area.maxY - 22))
        }
    }

    private static func drawBoar(ctx: CGContext, center: CGPoint) {
        let cx = center.x, cy = center.y
        // 몸통 (갈색 타원)
        ctx.setFillColor(UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 14, y: cy - 6, width: 28, height: 12))
        // 머리
        ctx.fillEllipse(in: CGRect(x: cx - 18, y: cy - 8, width: 10, height: 10))
        // 코
        ctx.setFillColor(UIColor(red: 0.6, green: 0.45, blue: 0.3, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 21, y: cy - 4, width: 5, height: 4))
        // 다리
        ctx.setFillColor(UIColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 10, y: cy + 5, width: 3, height: 5))
        ctx.fill(CGRect(x: cx + 7, y: cy + 5, width: 3, height: 5))
    }

    // MARK: - 8월 억새 (공산)

    private static func drawPampasGrass(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 억새 줄기들
        let grassGreen = UIColor(red: 0.45, green: 0.55, blue: 0.25, alpha: 1)
        ctx.setStrokeColor(grassGreen.cgColor)
        ctx.setLineWidth(1.5)
        ctx.setLineCap(.round)

        for i in 0..<5 {
            let baseX = cx - 12 + CGFloat(i) * 6
            let topOffset = CGFloat(i % 2 == 0 ? -3 : 3)
            ctx.move(to: CGPoint(x: baseX, y: area.maxY - 8))
            ctx.addQuadCurve(to: CGPoint(x: baseX + topOffset, y: cy - 10),
                             control: CGPoint(x: baseX + topOffset * 0.5, y: cy + 10))
            ctx.strokePath()
        }

        // 억새 꼭대기 (은빛 솜)
        let silverColor = UIColor(red: 0.85, green: 0.82, blue: 0.72, alpha: 0.8)
        for i in 0..<5 {
            let baseX = cx - 12 + CGFloat(i) * 6
            let topOffset = CGFloat(i % 2 == 0 ? -3 : 3)
            drawOvalClump(ctx: ctx, center: CGPoint(x: baseX + topOffset, y: cy - 15), rx: 4, ry: 8, color: silverColor)
        }

        // 광: 보름달
        if card.type == .bright {
            let moonSize: CGFloat = 30
            let moonRect = CGRect(x: cx - moonSize / 2, y: area.minY + 2, width: moonSize, height: moonSize)
            // 달 후광
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: [
                                            UIColor(red: 1, green: 0.92, blue: 0.4, alpha: 0.5).cgColor,
                                            UIColor(red: 1, green: 0.85, blue: 0, alpha: 0).cgColor
                                         ] as CFArray,
                                         locations: [0, 1]) {
                ctx.drawRadialGradient(gradient,
                                       startCenter: CGPoint(x: moonRect.midX, y: moonRect.midY),
                                       startRadius: moonSize / 2,
                                       endCenter: CGPoint(x: moonRect.midX, y: moonRect.midY),
                                       endRadius: moonSize,
                                       options: [])
            }
            // 달 본체
            ctx.setFillColor(UIColor(red: 1.0, green: 0.88, blue: 0.30, alpha: 1).cgColor)
            ctx.fillEllipse(in: moonRect)
            ctx.setFillColor(UIColor(red: 0.95, green: 0.82, blue: 0.25, alpha: 1).cgColor)
            ctx.fillEllipse(in: moonRect.insetBy(dx: 3, dy: 3))
        }

        // 열끗: 기러기
        if card.type == .animal {
            drawGeese(ctx: ctx, center: CGPoint(x: cx, y: area.minY + 20))
        }
    }

    private static func drawGeese(ctx: CGContext, center: CGPoint) {
        ctx.setStrokeColor(UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.9).cgColor)
        ctx.setLineWidth(2)
        ctx.setLineCap(.round)

        // V자 기러기 3마리
        for i in 0..<3 {
            let ox = center.x - 12 + CGFloat(i) * 12
            let oy = center.y + CGFloat(i % 2 == 0 ? 0 : -5)
            ctx.move(to: CGPoint(x: ox - 5, y: oy + 3))
            ctx.addLine(to: CGPoint(x: ox, y: oy))
            ctx.addLine(to: CGPoint(x: ox + 5, y: oy + 3))
            ctx.strokePath()
        }
    }

    // MARK: - 9월 국화 (菊)

    private static func drawChrysanthemum(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY - 5

        // 큰 국화 (노란/보라)
        let chrysYellow = UIColor(red: 0.90, green: 0.75, blue: 0.10, alpha: 1)
        let chrysOrange = UIColor(red: 0.90, green: 0.60, blue: 0.15, alpha: 1)

        // 바깥 꽃잎
        let petalCount = 12
        for i in 0..<petalCount {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(petalCount))
            let px = cx + cos(angle) * 16
            let py = cy + sin(angle) * 16
            ctx.setFillColor((i % 2 == 0 ? chrysYellow : chrysOrange).cgColor)
            ctx.fillEllipse(in: CGRect(x: px - 5, y: py - 3, width: 10, height: 6))
        }

        // 안쪽 꽃잎
        for i in 0..<8 {
            let angle = CGFloat(i) * (2 * .pi / 8) + 0.2
            let px = cx + cos(angle) * 8
            let py = cy + sin(angle) * 8
            ctx.setFillColor(chrysYellow.cgColor)
            ctx.fillEllipse(in: CGRect(x: px - 4, y: py - 2.5, width: 8, height: 5))
        }

        // 중심
        ctx.setFillColor(UIColor(red: 0.75, green: 0.55, blue: 0.10, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 4, y: cy - 4, width: 8, height: 8))

        // 잎
        let leafGreen = UIColor(red: 0.20, green: 0.48, blue: 0.18, alpha: 0.8)
        drawLeaf(ctx: ctx, center: CGPoint(x: cx - 18, y: cy + 20), length: 14, angle: -0.4, color: leafGreen)
        drawLeaf(ctx: ctx, center: CGPoint(x: cx + 16, y: cy + 18), length: 12, angle: 0.5, color: leafGreen)

        // 열끗: 술잔
        if card.type == .animal {
            drawSakeCup(ctx: ctx, center: CGPoint(x: cx, y: area.maxY - 22))
        }
    }

    private static func drawSakeCup(ctx: CGContext, center: CGPoint) {
        let cx = center.x, cy = center.y
        // 잔 (빨간 반원)
        let cupPath = UIBezierPath()
        cupPath.move(to: CGPoint(x: cx - 10, y: cy - 3))
        cupPath.addQuadCurve(to: CGPoint(x: cx + 10, y: cy - 3),
                             control: CGPoint(x: cx, y: cy + 10))
        cupPath.close()
        UIColor(red: 0.80, green: 0.15, blue: 0.12, alpha: 1).setFill()
        cupPath.fill()

        // 잔 위 (테두리)
        ctx.setStrokeColor(UIColor(red: 0.60, green: 0.08, blue: 0.10, alpha: 1).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: cx - 12, y: cy - 3))
        ctx.addLine(to: CGPoint(x: cx + 12, y: cy - 3))
        ctx.strokePath()
    }

    // MARK: - 10월 단풍 (楓)

    private static func drawMaple(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY - 5

        // 단풍잎들
        let mapleRed = UIColor(red: 0.90, green: 0.20, blue: 0.10, alpha: 1)
        let mapleOrange = UIColor(red: 0.92, green: 0.45, blue: 0.10, alpha: 0.9)
        let mapleYellow = UIColor(red: 0.90, green: 0.70, blue: 0.15, alpha: 0.85)

        drawMapleLeaf(ctx: ctx, center: CGPoint(x: cx - 5, y: cy - 8), size: 14, color: mapleRed)
        drawMapleLeaf(ctx: ctx, center: CGPoint(x: cx + 12, y: cy - 15), size: 11, color: mapleOrange)
        drawMapleLeaf(ctx: ctx, center: CGPoint(x: cx - 15, y: cy + 5), size: 10, color: mapleYellow)
        drawMapleLeaf(ctx: ctx, center: CGPoint(x: cx + 8, y: cy + 8), size: 9, color: mapleRed)

        // 가지
        ctx.setStrokeColor(UIColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 0.7).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx, y: cy + 15))
        ctx.addLine(to: CGPoint(x: cx - 5, y: area.maxY - 10))
        ctx.strokePath()

        // 열끗: 사슴
        if card.type == .animal {
            drawDeer(ctx: ctx, center: CGPoint(x: cx, y: area.maxY - 20))
        }
    }

    private static func drawMapleLeaf(ctx: CGContext, center: CGPoint, size: CGFloat, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        // 단풍잎 (5갈래 별 모양)
        let path = UIBezierPath()
        let points = 5
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let r = i % 2 == 0 ? size : size * 0.45
            let px = center.x + cos(angle) * r
            let py = center.y + sin(angle) * r
            if i == 0 {
                path.move(to: CGPoint(x: px, y: py))
            } else {
                path.addLine(to: CGPoint(x: px, y: py))
            }
        }
        path.close()
        path.fill()

        // 줄기
        ctx.setStrokeColor(color.withAlphaComponent(0.6).cgColor)
        ctx.setLineWidth(0.8)
        ctx.move(to: CGPoint(x: center.x, y: center.y))
        ctx.addLine(to: CGPoint(x: center.x, y: center.y + size + 3))
        ctx.strokePath()
    }

    private static func drawDeer(ctx: CGContext, center: CGPoint) {
        let cx = center.x, cy = center.y

        // 몸통
        ctx.setFillColor(UIColor(red: 0.60, green: 0.40, blue: 0.18, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 12, y: cy - 5, width: 24, height: 10))

        // 머리
        ctx.fillEllipse(in: CGRect(x: cx + 10, y: cy - 10, width: 8, height: 8))

        // 뿔
        ctx.setStrokeColor(UIColor(red: 0.45, green: 0.30, blue: 0.12, alpha: 1).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx + 14, y: cy - 10))
        ctx.addLine(to: CGPoint(x: cx + 12, y: cy - 18))
        ctx.addLine(to: CGPoint(x: cx + 10, y: cy - 14))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx + 16, y: cy - 10))
        ctx.addLine(to: CGPoint(x: cx + 20, y: cy - 17))
        ctx.addLine(to: CGPoint(x: cx + 22, y: cy - 13))
        ctx.strokePath()

        // 다리
        ctx.setFillColor(UIColor(red: 0.50, green: 0.33, blue: 0.15, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 8, y: cy + 4, width: 2, height: 6))
        ctx.fill(CGRect(x: cx + 6, y: cy + 4, width: 2, height: 6))
    }

    // MARK: - 11월 오동 (梧桐)

    private static func drawPaulownia(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 줄기
        ctx.setStrokeColor(UIColor(red: 0.35, green: 0.28, blue: 0.15, alpha: 1).cgColor)
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: cx, y: area.maxY - 5))
        ctx.addLine(to: CGPoint(x: cx, y: cy - 5))
        ctx.strokePath()

        // 큰 잎 3장
        let paulGreen = UIColor(red: 0.25, green: 0.42, blue: 0.20, alpha: 0.85)
        let paulLight = UIColor(red: 0.35, green: 0.55, blue: 0.28, alpha: 0.8)

        // 중앙 잎
        drawBroadLeaf(ctx: ctx, base: CGPoint(x: cx, y: cy - 5), angle: -.pi / 2, length: 24, width: 20, color: paulGreen)
        // 좌측 잎
        drawBroadLeaf(ctx: ctx, base: CGPoint(x: cx - 3, y: cy), angle: -.pi / 2 - 0.6, length: 20, width: 16, color: paulLight)
        // 우측 잎
        drawBroadLeaf(ctx: ctx, base: CGPoint(x: cx + 3, y: cy), angle: -.pi / 2 + 0.6, length: 20, width: 16, color: paulLight)

        // 광: 봉황 (간략화)
        if card.type == .bright {
            // 봉황 대신 화려한 금색 장식
            let phoenixCenter = CGPoint(x: cx, y: area.minY + 20)
            ctx.setFillColor(UIColor(red: 0.85, green: 0.65, blue: 0.10, alpha: 0.8).cgColor)
            ctx.fillEllipse(in: CGRect(x: phoenixCenter.x - 8, y: phoenixCenter.y - 5, width: 16, height: 10))
            // 날개
            ctx.setStrokeColor(UIColor(red: 0.80, green: 0.55, blue: 0.08, alpha: 0.9).cgColor)
            ctx.setLineWidth(1.5)
            ctx.move(to: CGPoint(x: phoenixCenter.x - 6, y: phoenixCenter.y))
            ctx.addQuadCurve(to: CGPoint(x: phoenixCenter.x - 18, y: phoenixCenter.y - 8),
                             control: CGPoint(x: phoenixCenter.x - 14, y: phoenixCenter.y + 3))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: phoenixCenter.x + 6, y: phoenixCenter.y))
            ctx.addQuadCurve(to: CGPoint(x: phoenixCenter.x + 18, y: phoenixCenter.y - 8),
                             control: CGPoint(x: phoenixCenter.x + 14, y: phoenixCenter.y + 3))
            ctx.strokePath()
        }
    }

    private static func drawBroadLeaf(ctx: CGContext, base: CGPoint, angle: CGFloat, length: CGFloat, width: CGFloat, color: UIColor) {
        let tip = CGPoint(x: base.x + cos(angle) * length, y: base.y + sin(angle) * length)
        let perpAngle = angle + .pi / 2
        let halfW = width / 2

        let left = CGPoint(x: base.x + cos(perpAngle) * halfW + cos(angle) * length * 0.4,
                           y: base.y + sin(perpAngle) * halfW + sin(angle) * length * 0.4)
        let right = CGPoint(x: base.x - cos(perpAngle) * halfW + cos(angle) * length * 0.4,
                            y: base.y - sin(perpAngle) * halfW + sin(angle) * length * 0.4)

        let path = UIBezierPath()
        path.move(to: base)
        path.addQuadCurve(to: tip, control: left)
        path.addQuadCurve(to: base, control: right)
        path.close()

        color.setFill()
        path.fill()

        // 잎맥
        ctx.setStrokeColor(color.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: base)
        ctx.addLine(to: tip)
        ctx.strokePath()
    }

    // MARK: - 12월 비 (버드나무)

    private static func drawWillow(ctx: CGContext, area: CGRect, card: Card) {
        let cx = area.midX, cy = area.midY

        // 비 줄기 (수양버들 가지)
        ctx.setStrokeColor(UIColor(red: 0.30, green: 0.45, blue: 0.20, alpha: 0.9).cgColor)
        ctx.setLineWidth(1.5)
        ctx.setLineCap(.round)

        for i in 0..<6 {
            let startX = area.minX + 10 + CGFloat(i) * 14
            ctx.move(to: CGPoint(x: startX, y: area.minY + 8))
            ctx.addQuadCurve(to: CGPoint(x: startX + CGFloat(i % 2 == 0 ? 5 : -5), y: area.maxY - 15),
                             control: CGPoint(x: startX + CGFloat(i % 2 == 0 ? -8 : 8), y: cy))
            ctx.strokePath()
        }

        // 빗줄기
        ctx.setStrokeColor(UIColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 0.4).cgColor)
        ctx.setLineWidth(0.8)
        for i in 0..<8 {
            let rx = area.minX + 8 + CGFloat(i) * 12
            let ry1 = area.minY + CGFloat(i % 3) * 8
            ctx.move(to: CGPoint(x: rx, y: ry1))
            ctx.addLine(to: CGPoint(x: rx - 3, y: ry1 + 15))
            ctx.strokePath()
        }

        // 광: 우산 쓴 사람
        if card.type == .bright {
            drawUmbrellaMan(ctx: ctx, center: CGPoint(x: cx, y: cy + 10))
        }

        // 열끗: 제비
        if card.type == .animal {
            drawSwallow(ctx: ctx, center: CGPoint(x: cx + 10, y: area.minY + 25))
        }
    }

    private static func drawUmbrellaMan(ctx: CGContext, center: CGPoint) {
        let cx = center.x, cy = center.y

        // 우산
        let umbrellaPath = UIBezierPath()
        umbrellaPath.move(to: CGPoint(x: cx - 18, y: cy - 5))
        umbrellaPath.addQuadCurve(to: CGPoint(x: cx + 18, y: cy - 5),
                                  control: CGPoint(x: cx, y: cy - 28))
        umbrellaPath.addLine(to: CGPoint(x: cx - 18, y: cy - 5))
        umbrellaPath.close()
        UIColor(red: 0.80, green: 0.15, blue: 0.12, alpha: 0.9).setFill()
        umbrellaPath.fill()

        // 우산대
        ctx.setStrokeColor(UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx, y: cy - 20))
        ctx.addLine(to: CGPoint(x: cx, y: cy + 8))
        ctx.strokePath()

        // 몸통
        ctx.setFillColor(UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.8).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 5, y: cy + 2, width: 10, height: 14))

        // 발
        ctx.setStrokeColor(UIColor(red: 0.2, green: 0.15, blue: 0.10, alpha: 0.8).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx - 2, y: cy + 14))
        ctx.addLine(to: CGPoint(x: cx - 5, y: cy + 22))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx + 2, y: cy + 14))
        ctx.addLine(to: CGPoint(x: cx + 5, y: cy + 22))
        ctx.strokePath()
    }

    private static func drawSwallow(ctx: CGContext, center: CGPoint) {
        let cx = center.x, cy = center.y
        // 몸통
        ctx.setFillColor(UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 4, y: cy - 2, width: 8, height: 5))
        // 날개
        ctx.setStrokeColor(UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx - 2, y: cy))
        ctx.addLine(to: CGPoint(x: cx - 12, y: cy - 6))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx + 2, y: cy))
        ctx.addLine(to: CGPoint(x: cx + 12, y: cy - 6))
        ctx.strokePath()
        // 꼬리 (제비 특유의 갈래)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: cx, y: cy + 2))
        ctx.addLine(to: CGPoint(x: cx - 4, y: cy + 8))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx, y: cy + 2))
        ctx.addLine(to: CGPoint(x: cx + 4, y: cy + 8))
        ctx.strokePath()
    }

    // MARK: - 공통 드로잉 헬퍼

    /// 5잎 꽃
    private static func drawFlower5(ctx: CGContext, center: CGPoint, radius: CGFloat, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        let petals = 5
        for i in 0..<petals {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(petals)) - .pi / 2
            let px = center.x + cos(angle) * radius * 0.55
            let py = center.y + sin(angle) * radius * 0.55
            ctx.fillEllipse(in: CGRect(x: px - radius * 0.5, y: py - radius * 0.5,
                                       width: radius, height: radius))
        }
        // 꽃 중심
        ctx.setFillColor(UIColor(red: 0.90, green: 0.80, blue: 0.20, alpha: 0.9).cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - radius * 0.25, y: center.y - radius * 0.25,
                                   width: radius * 0.5, height: radius * 0.5))
    }

    /// 미니 꽃 (뒷면 패턴용)
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
        ctx.setFillColor(UIColor.yellow.withAlphaComponent(0.6).cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - radius * 0.4, y: center.y - radius * 0.4,
                                   width: radius * 0.8, height: radius * 0.8))
    }

    /// 타원형 뭉치
    private static func drawOvalClump(ctx: CGContext, center: CGPoint, rx: CGFloat, ry: CGFloat, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
    }

    /// 잎
    private static func drawLeaf(ctx: CGContext, center: CGPoint, length: CGFloat, angle: CGFloat, color: UIColor) {
        let tip = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
        let perpAngle = angle + .pi / 2
        let halfW = length * 0.3

        let ctrl1 = CGPoint(x: center.x + cos(perpAngle) * halfW + cos(angle) * length * 0.5,
                            y: center.y + sin(perpAngle) * halfW + sin(angle) * length * 0.5)
        let ctrl2 = CGPoint(x: center.x - cos(perpAngle) * halfW + cos(angle) * length * 0.5,
                            y: center.y - sin(perpAngle) * halfW + sin(angle) * length * 0.5)

        let path = UIBezierPath()
        path.move(to: center)
        path.addQuadCurve(to: tip, control: ctrl1)
        path.addQuadCurve(to: center, control: ctrl2)
        path.close()

        color.setFill()
        path.fill()
    }

    /// 작은 새
    private static func drawSmallBird(ctx: CGContext, center: CGPoint, bodyColor: UIColor) {
        let cx = center.x, cy = center.y
        // 몸통
        ctx.setFillColor(bodyColor.cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 6, y: cy - 4, width: 12, height: 8))
        // 머리
        ctx.fillEllipse(in: CGRect(x: cx + 4, y: cy - 7, width: 7, height: 7))
        // 부리
        ctx.setFillColor(UIColor(red: 0.8, green: 0.6, blue: 0.1, alpha: 1).cgColor)
        let beak = UIBezierPath()
        beak.move(to: CGPoint(x: cx + 10, y: cy - 4))
        beak.addLine(to: CGPoint(x: cx + 15, y: cy - 3))
        beak.addLine(to: CGPoint(x: cx + 10, y: cy - 2))
        beak.close()
        beak.fill()
        // 눈
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: cx + 7, y: cy - 6, width: 2, height: 2))
        // 꼬리
        ctx.setStrokeColor(bodyColor.cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx - 5, y: cy - 1))
        ctx.addLine(to: CGPoint(x: cx - 11, y: cy - 5))
        ctx.strokePath()
    }
}
