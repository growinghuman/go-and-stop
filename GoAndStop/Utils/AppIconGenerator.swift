import UIKit

/// 프로그래매틱 앱 아이콘 생성기
/// Xcode에서 빌드 시 Assets.xcassets/AppIcon에 등록할 아이콘 이미지를 생성
class AppIconGenerator {

    /// 앱 아이콘 생성 (1024x1024)
    static func generateAppIcon(size: CGFloat = 1024) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        return renderer.image { context in
            let ctx = context.cgContext
            let rect = CGRect(x: 0, y: 0, width: size, height: size)

            // 1. 배경 그라디언트 (진한 녹색 → 에메랄드)
            let gradientColors = [
                UIColor(red: 0.04, green: 0.20, blue: 0.10, alpha: 1).cgColor,
                UIColor(red: 0.07, green: 0.32, blue: 0.18, alpha: 1).cgColor,
                UIColor(red: 0.04, green: 0.22, blue: 0.12, alpha: 1).cgColor
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors as CFArray,
                locations: [0, 0.5, 1]
            )!
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: 0),
                                   end: CGPoint(x: size, y: size),
                                   options: [])

            // 2. 장식 패턴 (바닥판 질감)
            let patternColor = UIColor.white.withAlphaComponent(0.03)
            patternColor.setFill()
            for i in stride(from: 0, to: size, by: size / 12) {
                ctx.fill(CGRect(x: 0, y: i, width: size, height: 1))
                ctx.fill(CGRect(x: i, y: 0, width: 1, height: size))
            }

            // 3. 화투 카드 3장 (부채꼴 배치)
            let cardWidth = size * 0.25
            let cardHeight = cardWidth * 1.5
            let centerX = size * 0.5
            let centerY = size * 0.42

            drawCard(ctx: ctx, x: centerX - cardWidth * 0.9, y: centerY - cardHeight * 0.2,
                    width: cardWidth, height: cardHeight, rotation: -0.2,
                    monthColor: UIColor(red: 1, green: 0.4, blue: 0.5, alpha: 1), // 매화
                    type: "띠", symbolColor: UIColor(red: 0.8, green: 0.1, blue: 0.2, alpha: 1))

            drawCard(ctx: ctx, x: centerX - cardWidth * 0.15, y: centerY - cardHeight * 0.35,
                    width: cardWidth, height: cardHeight, rotation: 0,
                    monthColor: UIColor(red: 0.9, green: 0.8, blue: 0.3, alpha: 1), // 국화
                    type: "광", symbolColor: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1))

            drawCard(ctx: ctx, x: centerX + cardWidth * 0.5, y: centerY - cardHeight * 0.2,
                    width: cardWidth, height: cardHeight, rotation: 0.2,
                    monthColor: UIColor(red: 0.3, green: 0.6, blue: 1, alpha: 1), // 비
                    type: "열끗", symbolColor: UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1))

            // 4. "맞고" 타이틀 텍스트
            let titleFont = UIFont.systemFont(ofSize: size * 0.16, weight: .black)
            let titleText = "맞 고" as NSString

            // 금색 그라디언트 효과 (텍스트 아웃라인 + 채움)
            let titleSize = titleText.size(withAttributes: [.font: titleFont])
            let titleX = (size - titleSize.width) / 2
            let titleY = size * 0.66

            // 텍스트 그림자
            let shadowAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black.withAlphaComponent(0.6)
            ]
            titleText.draw(at: CGPoint(x: titleX + 3, y: titleY + 3), withAttributes: shadowAttrs)

            // 메인 텍스트 (금색)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1),
                .strokeColor: UIColor(red: 0.8, green: 0.6, blue: 0, alpha: 1),
                .strokeWidth: -2
            ]
            titleText.draw(at: CGPoint(x: titleX, y: titleY), withAttributes: titleAttrs)

            // 5. 서브타이틀
            let subFont = UIFont.systemFont(ofSize: size * 0.045, weight: .medium)
            let subText = "GO & STOP" as NSString
            let subSize = subText.size(withAttributes: [.font: subFont])
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: subFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7),
                .kern: 4
            ]
            subText.draw(at: CGPoint(x: (size - subSize.width) / 2, y: size * 0.83),
                        withAttributes: subAttrs)

            // 6. 하단 장식선
            let lineY = size * 0.91
            ctx.setStrokeColor(UIColor(red: 1, green: 0.84, blue: 0, alpha: 0.3).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: size * 0.2, y: lineY))
            ctx.addLine(to: CGPoint(x: size * 0.8, y: lineY))
            ctx.strokePath()
        }
    }

    /// 카드 1장 그리기
    private static func drawCard(ctx: CGContext, x: CGFloat, y: CGFloat,
                                  width: CGFloat, height: CGFloat, rotation: CGFloat,
                                  monthColor: UIColor, type: String, symbolColor: UIColor) {
        ctx.saveGState()

        ctx.translateBy(x: x + width / 2, y: y + height / 2)
        ctx.rotate(by: rotation)
        ctx.translateBy(x: -width / 2, y: -height / 2)

        let cardRect = CGRect(x: 0, y: 0, width: width, height: height)
        let cornerRadius: CGFloat = width * 0.08

        // 카드 그림자
        ctx.setShadow(offset: CGSize(width: 4, height: 4), blur: 10,
                      color: UIColor.black.withAlphaComponent(0.4).cgColor)

        // 카드 배경 (크림색)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cornerRadius)
        UIColor(red: 0.98, green: 0.96, blue: 0.9, alpha: 1).setFill()
        cardPath.fill()

        ctx.setShadow(offset: .zero, blur: 0)

        // 카드 테두리
        UIColor(red: 0.7, green: 0.6, blue: 0.4, alpha: 1).setStroke()
        cardPath.lineWidth = 2
        cardPath.stroke()

        // 상단 색상 배너
        let bannerRect = CGRect(x: 4, y: 4, width: width - 8, height: height * 0.25)
        let bannerPath = UIBezierPath(roundedRect: bannerRect, cornerRadius: cornerRadius * 0.5)
        monthColor.setFill()
        bannerPath.fill()

        // 타입 심볼
        let symbolFont = UIFont.systemFont(ofSize: width * 0.25, weight: .bold)
        let symbolAttrs: [NSAttributedString.Key: Any] = [
            .font: symbolFont,
            .foregroundColor: symbolColor
        ]
        let symbolText = type as NSString
        let symbolSize = symbolText.size(withAttributes: symbolAttrs)
        symbolText.draw(at: CGPoint(
            x: (width - symbolSize.width) / 2,
            y: height * 0.45
        ), withAttributes: symbolAttrs)

        ctx.restoreGState()
    }

    /// 모든 필요한 사이즈의 아이콘 생성
    static func generateAllSizes() -> [(String, UIImage)] {
        let sizes: [(String, CGFloat)] = [
            ("AppIcon-1024", 1024),
            ("AppIcon-180", 180),    // iPhone @3x
            ("AppIcon-120", 120),    // iPhone @2x
            ("AppIcon-167", 167),    // iPad Pro @2x
            ("AppIcon-152", 152),    // iPad @2x
            ("AppIcon-76", 76),      // iPad @1x
            ("AppIcon-40", 40),      // Spotlight @1x
            ("AppIcon-80", 80),      // Spotlight @2x
            ("AppIcon-120s", 120),   // Spotlight @3x
            ("AppIcon-58", 58),      // Settings @2x
            ("AppIcon-87", 87),      // Settings @3x
        ]

        return sizes.map { (name, size) in
            (name, generateAppIcon(size: size))
        }
    }
}
