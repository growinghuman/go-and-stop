import SpriteKit

/// 순차적 애니메이션 실행을 위한 체인 매니저
class AnimationChain {
    private var steps: [AnimationStep] = []
    private var onComplete: (() -> Void)?

    struct AnimationStep {
        let action: (@escaping () -> Void) -> Void
        let delay: TimeInterval
    }

    @discardableResult
    func then(delay: TimeInterval = 0, action: @escaping (@escaping () -> Void) -> Void) -> AnimationChain {
        steps.append(AnimationStep(action: action, delay: delay))
        return self
    }

    @discardableResult
    func onComplete(_ handler: @escaping () -> Void) -> AnimationChain {
        self.onComplete = handler
        return self
    }

    func execute() {
        executeStep(at: 0)
    }

    private func executeStep(at index: Int) {
        guard index < steps.count else {
            onComplete?()
            return
        }

        let step = steps[index]
        if step.delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
                step.action {
                    self.executeStep(at: index + 1)
                }
            }
        } else {
            step.action {
                self.executeStep(at: index + 1)
            }
        }
    }
}

// MARK: - SKNode convenience for chained animations

extension SKNode {

    /// 이동 후 콜백
    func animateMove(to point: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
        let action = SKAction.move(to: point, duration: duration)
        action.timingMode = .easeInEaseOut
        run(action, completion: completion)
    }

    /// 바운스 이동
    func animateBounceMove(to point: CGPoint, completion: @escaping () -> Void) {
        let duration: TimeInterval = 0.2
        let move = SKAction.move(to: point, duration: duration)
        move.timingMode = .easeIn

        let overshoot = SKAction.moveBy(x: 0, y: -4, duration: 0.04)
        let bounce = SKAction.moveBy(x: 0, y: 4, duration: 0.04)

        run(SKAction.sequence([move, overshoot, bounce]), completion: completion)
    }

    /// 페이드인 + 스케일
    func animateAppear(duration: TimeInterval = 0.2, completion: @escaping () -> Void) {
        self.alpha = 0
        self.setScale(0.5)

        let fadeIn = SKAction.fadeIn(withDuration: duration)
        let scale = SKAction.scale(to: 1.0, duration: duration)
        scale.timingMode = .easeOut

        run(SKAction.group([fadeIn, scale]), completion: completion)
    }

    /// 카드 수집 이동 (축소하며 이동)
    func animateCollect(to point: CGPoint, completion: @escaping () -> Void) {
        let move = SKAction.move(to: point, duration: 0.25)
        move.timingMode = .easeIn
        let scale = SKAction.scale(to: 0.55, duration: 0.25)
        let fade = SKAction.fadeAlpha(to: 0.8, duration: 0.25)

        run(SKAction.group([move, scale, fade]), completion: completion)
    }

    /// 화면 밖으로 날리기
    func animateFlyAway(direction: CGFloat = 1, completion: @escaping () -> Void) {
        let move = SKAction.moveBy(x: direction * 400, y: CGFloat.random(in: -100...100), duration: 0.4)
        let rotate = SKAction.rotate(byAngle: direction * 2, duration: 0.4)
        let fade = SKAction.fadeOut(withDuration: 0.3)

        run(SKAction.group([move, rotate, fade])) {
            self.removeFromParent()
            completion()
        }
    }
}

// MARK: - 점수 카운팅 애니메이션 노드

class ScoreCounterNode: SKLabelNode {
    private var targetValue: Int = 0
    private var currentValue: Int = 0
    private var timer: Timer?

    func countTo(_ value: Int, duration: TimeInterval = 1.5) {
        targetValue = value
        currentValue = 0
        let steps = min(value, 30)
        let interval = duration / Double(steps)
        let increment = max(1, value / steps)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.currentValue = min(self.currentValue + increment, self.targetValue)
            self.text = "\(self.currentValue)점"

            // 숫자 바뀔 때 살짝 크기 변화
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ])
            self.run(pulse)

            if self.currentValue >= self.targetValue {
                timer.invalidate()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
