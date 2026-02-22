import SpriteKit

/// 시각 이펙트 관리자
class EffectManager {
    weak var scene: SKScene?

    init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - 승리 이펙트

    func showWinEffect(at position: CGPoint) {
        guard let scene = scene else { return }

        // 금색 파티클 폭발
        let colors: [UIColor] = [.systemYellow, .systemOrange, .systemRed, .white]

        for i in 0..<30 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = colors.randomElement()!
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 100

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...200)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let destination = CGPoint(x: position.x + dx, y: position.y + dy)

            let delay = SKAction.wait(forDuration: Double(i) * 0.02)
            let move = SKAction.move(to: destination, duration: Double.random(in: 0.5...1.0))
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let scale = SKAction.scale(to: 0.1, duration: 0.8)
            let group = SKAction.group([move, fade, scale])
            let remove = SKAction.removeFromParent()

            scene.addChild(particle)
            particle.run(SKAction.sequence([delay, group, remove]))
        }

        // "승리!" 텍스트
        showBigText("승리!", color: .systemYellow, at: position)
    }

    // MARK: - 폭탄 이펙트

    func showBombEffect(at position: CGPoint) {
        guard let scene = scene else { return }

        // 화면 흔들기
        shakeScreen(intensity: 10, duration: 0.3)

        // 폭발 원형
        let explosion = SKShapeNode(circleOfRadius: 5)
        explosion.fillColor = .systemRed
        explosion.strokeColor = .systemOrange
        explosion.lineWidth = 3
        explosion.position = position
        explosion.zPosition = 100
        scene.addChild(explosion)

        let expand = SKAction.scale(to: 15, duration: 0.3)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([expand, fade, remove]))

        // 파편
        for _ in 0..<15 {
            let shard = SKShapeNode(rectOf: CGSize(width: 4, height: 8), cornerRadius: 1)
            shard.fillColor = [UIColor.red, .orange, .yellow].randomElement()!
            shard.strokeColor = .clear
            shard.position = position
            shard.zPosition = 101

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 50...150)
            let move = SKAction.move(to: CGPoint(x: position.x + cos(angle) * dist,
                                                  y: position.y + sin(angle) * dist),
                                    duration: 0.4)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.4)
            let fade2 = SKAction.fadeOut(withDuration: 0.3)

            scene.addChild(shard)
            shard.run(SKAction.sequence([
                SKAction.group([move, rotate]),
                fade2,
                SKAction.removeFromParent()
            ]))
        }

        showBigText("폭탄!", color: .systemRed, at: position)
    }

    // MARK: - 광 획득 이펙트

    func showBrightEffect(at position: CGPoint) {
        guard let scene = scene else { return }

        // 빛 기둥
        let beam = SKShapeNode(rectOf: CGSize(width: 60, height: scene.size.height))
        beam.fillColor = UIColor.systemYellow.withAlphaComponent(0.3)
        beam.strokeColor = .clear
        beam.position = CGPoint(x: position.x, y: scene.size.height / 2)
        beam.zPosition = 90
        beam.alpha = 0
        scene.addChild(beam)

        let fadeIn = SKAction.fadeAlpha(to: 0.6, duration: 0.2)
        let wait = SKAction.wait(forDuration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        beam.run(SKAction.sequence([fadeIn, wait, fadeOut, SKAction.removeFromParent()]))

        // 반짝이는 별
        for _ in 0..<8 {
            let star = SKLabelNode(text: "✨")
            star.fontSize = CGFloat.random(in: 14...24)
            star.position = CGPoint(x: position.x + CGFloat.random(in: -40...40),
                                    y: position.y + CGFloat.random(in: -40...40))
            star.zPosition = 95
            star.alpha = 0
            scene.addChild(star)

            let delay = SKAction.wait(forDuration: Double.random(in: 0...0.3))
            let fadeIn2 = SKAction.fadeIn(withDuration: 0.15)
            let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
            let fadeOut2 = SKAction.fadeOut(withDuration: 0.3)
            star.run(SKAction.sequence([delay, fadeIn2, scaleUp, fadeOut2, SKAction.removeFromParent()]))
        }

        showBigText("光", color: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1), at: position, fontSize: 40)
    }

    // MARK: - 고도리 이펙트

    func showGodoriEffect(at position: CGPoint) {
        guard let scene = scene else { return }

        // 새 3마리 날아오는 연출
        let birds = ["🐦", "🐤", "🦆"]
        for (i, bird) in birds.enumerated() {
            let birdNode = SKLabelNode(text: bird)
            birdNode.fontSize = 30
            birdNode.position = CGPoint(x: -50, y: position.y + CGFloat(i - 1) * 30)
            birdNode.zPosition = 100
            scene.addChild(birdNode)

            let delay = SKAction.wait(forDuration: Double(i) * 0.15)
            let flyAcross = SKAction.moveTo(x: scene.size.width + 50, duration: 1.2)
            flyAcross.timingMode = .easeInEaseOut

            // 물결치듯 날기
            let wave = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 15, duration: 0.15),
                SKAction.moveBy(x: 0, y: -15, duration: 0.15)
            ])
            let waveRepeat = SKAction.repeatForever(wave)

            birdNode.run(SKAction.sequence([
                delay,
                SKAction.group([flyAcross, waveRepeat]),
                SKAction.removeFromParent()
            ]))
        }

        showBigText("고도리!", color: .systemGreen, at: position)
    }

    // MARK: - 쓸 이펙트

    func showSsulEffect() {
        guard let scene = scene else { return }

        // 바닥 전체 쓸어가기 이펙트
        let sweep = SKShapeNode(rectOf: CGSize(width: scene.size.width, height: 3))
        sweep.fillColor = .systemYellow
        sweep.strokeColor = .clear
        sweep.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.5)
        sweep.alpha = 0.8
        sweep.zPosition = 90
        scene.addChild(sweep)

        let moveDown = SKAction.moveTo(y: scene.size.height * 0.3, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.2)
        sweep.run(SKAction.sequence([moveDown, fade, SKAction.removeFromParent()]))

        showBigText("쓸!", color: .systemYellow, at: CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.45))
    }

    // MARK: - 쪽 이펙트

    func showJjokEffect(at position: CGPoint) {
        showBigText("쪽!", color: .systemCyan, at: position)

        // 스파클
        for _ in 0..<6 {
            guard let scene = scene else { return }
            let sparkle = SKLabelNode(text: "⭐")
            sparkle.fontSize = 16
            sparkle.position = position
            sparkle.zPosition = 95
            scene.addChild(sparkle)

            let move = SKAction.moveBy(x: CGFloat.random(in: -40...40),
                                       y: CGFloat.random(in: -40...40),
                                       duration: 0.4)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            sparkle.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }

    // MARK: - 뻑 이펙트

    func showPpukEffect(at position: CGPoint) {
        showBigText("뻑!", color: .systemRed, at: position, fontSize: 30)
        shakeScreen(intensity: 3, duration: 0.15)
    }

    // MARK: - 고/스톱 이펙트

    func showGoEffect(at position: CGPoint, goCount: Int) {
        let text = goCount >= 3 ? "쓰리고!" : "고!"
        let color: UIColor = goCount >= 3 ? .systemRed : .systemOrange
        showBigText(text, color: color, at: position, fontSize: 36)
    }

    func showStopEffect(at position: CGPoint) {
        showBigText("스톱!", color: .systemBlue, at: position, fontSize: 36)
    }

    // MARK: - 패배 이펙트

    func showLoseEffect(at position: CGPoint) {
        showBigText("패배...", color: .gray, at: position, fontSize: 30)
    }

    // MARK: - 유틸리티

    func showBigText(_ text: String, color: UIColor, at position: CGPoint, fontSize: CGFloat = 28) {
        guard let scene = scene else { return }

        let label = SKLabelNode(text: text)
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = fontSize
        label.fontColor = color
        label.position = position
        label.zPosition = 110
        label.alpha = 0
        label.setScale(0.3)
        scene.addChild(label)

        // 그림자
        let shadow = SKLabelNode(text: text)
        shadow.fontName = "HelveticaNeue-Bold"
        shadow.fontSize = fontSize
        shadow.fontColor = .black.withAlphaComponent(0.5)
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        label.addChild(shadow)

        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.2, duration: 0.15)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.8)
        let disappear = SKAction.group([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.moveBy(x: 0, y: 30, duration: 0.3)
        ])
        let remove = SKAction.removeFromParent()

        label.run(SKAction.sequence([appear, settle, wait, disappear, remove]))
    }

    func shakeScreen(intensity: CGFloat, duration: TimeInterval) {
        guard let scene = scene else { return }

        let numberOfShakes = Int(duration / 0.04)
        var actions: [SKAction] = []

        for _ in 0..<numberOfShakes {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.02))
            actions.append(SKAction.moveBy(x: -dx, y: -dy, duration: 0.02))
        }

        scene.run(SKAction.sequence(actions))
    }

    // MARK: - 나가리 이펙트

    func showNagariEffect(at position: CGPoint) {
        guard let scene = scene else { return }

        // 어두운 오버레이
        let overlay = SKShapeNode(rectOf: scene.size)
        overlay.fillColor = UIColor.black.withAlphaComponent(0.3)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        overlay.zPosition = 89
        overlay.alpha = 0
        scene.addChild(overlay)

        let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.3)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        overlay.run(SKAction.sequence([fadeIn, wait, fadeOut, SKAction.removeFromParent()]))

        showBigText("나가리!", color: .white, at: position, fontSize: 36)
    }

    // MARK: - 흔듦 이펙트

    func showShakeEffect(at position: CGPoint) {
        shakeScreen(intensity: 6, duration: 0.3)
        showBigText("흔듦!", color: .systemPurple, at: position, fontSize: 30)
    }

    // MARK: - 점수 달성 이펙트

    func showScoreReached(score: Int, at position: CGPoint) {
        guard let scene = scene else { return }

        let label = SKLabelNode(text: "\(score)점 달성!")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 22
        label.fontColor = .systemYellow
        label.position = position
        label.zPosition = 105
        label.alpha = 0
        scene.addChild(label)

        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.2, duration: 0.2)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.6)
        let fly = SKAction.group([
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.moveBy(x: 0, y: 40, duration: 0.4)
        ])

        label.run(SKAction.sequence([appear, settle, wait, fly, SKAction.removeFromParent()]))
    }
}
