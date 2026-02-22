import UIKit
import CoreHaptics

/// 햅틱 피드백 관리자
class HapticManager {
    static let shared = HapticManager()

    private var hapticEngine: CHHapticEngine?
    var isEnabled: Bool = true
    var intensity: Float = 1.0

    private init() {
        setupHapticEngine()
    }

    // MARK: - Setup

    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.playsHapticsOnly = true
            hapticEngine?.stoppedHandler = { [weak self] reason in
                self?.restartEngine()
            }
            hapticEngine?.resetHandler = { [weak self] in
                self?.restartEngine()
            }
            try hapticEngine?.start()
        } catch {
            print("Haptic engine setup failed: \(error)")
        }
    }

    private func restartEngine() {
        do {
            try hapticEngine?.start()
        } catch {
            print("Haptic engine restart failed: \(error)")
        }
    }

    // MARK: - 기본 피드백

    private func impactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: CGFloat(intensity))
    }

    private func notificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    private func selectionFeedback() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - 게임 이벤트별 햅틱

    /// 카드 선택 시 미세한 진동
    func playCardSelectHaptic() {
        selectionFeedback()
    }

    /// 카드 내려놓기 - 중간 강도 임팩트
    func playCardPlayHaptic() {
        impactFeedback(.medium)
    }

    /// 카드 매칭 먹기 - 가벼운 연타
    func playCardMatchHaptic() {
        impactFeedback(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.impactFeedback(.light)
        }
    }

    /// 폭탄 - 강한 진동 + 커스텀 패턴
    func playBombHaptic() {
        guard isEnabled else { return }
        playCustomPattern(events: [
            (0.0, 1.0, 0.8),   // 강한 충격
            (0.05, 0.8, 0.6),
            (0.1, 0.6, 0.4),
            (0.15, 0.4, 0.3),
            (0.2, 0.3, 0.2),
        ])
    }

    /// 흔듦 - 흔들리는 패턴
    func playShakeHaptic() {
        guard isEnabled else { return }
        playCustomPattern(events: [
            (0.0, 0.5, 0.3),
            (0.08, 0.7, 0.3),
            (0.16, 0.5, 0.3),
            (0.24, 0.7, 0.3),
        ])
    }

    /// 고 선언 - 상승 패턴
    func playGoHaptic() {
        guard isEnabled else { return }
        playCustomPattern(events: [
            (0.0, 0.4, 0.2),
            (0.08, 0.6, 0.2),
            (0.16, 0.8, 0.3),
        ])
    }

    /// 스톱/승리 - 점진적 강화
    func playStopHaptic() {
        notificationFeedback(.success)
    }

    /// 승리 - 환호 패턴
    func playWinHaptic() {
        guard isEnabled else { return }
        playCustomPattern(events: [
            (0.0, 0.5, 0.15),
            (0.1, 0.7, 0.15),
            (0.2, 0.9, 0.2),
            (0.35, 1.0, 0.25),
            (0.55, 0.8, 0.15),
            (0.7, 1.0, 0.2),
        ])
    }

    /// 대박 승리
    func playWinBigHaptic() {
        guard isEnabled else { return }
        playCustomPattern(events: [
            (0.0, 0.6, 0.1),
            (0.1, 0.8, 0.15),
            (0.2, 1.0, 0.2),
            (0.35, 0.7, 0.1),
            (0.45, 0.9, 0.15),
            (0.55, 1.0, 0.2),
            (0.7, 0.8, 0.1),
            (0.8, 1.0, 0.25),
        ])
    }

    /// 패배 - 하강 패턴
    func playLoseHaptic() {
        notificationFeedback(.error)
    }

    /// 광 획득 - 강한 단발
    func playBrightHaptic() {
        impactFeedback(.heavy)
    }

    /// 고도리 - 특별 패턴
    func playGodoriHaptic() {
        guard isEnabled else { return }
        playCustomPattern(events: [
            (0.0, 0.6, 0.1),
            (0.12, 0.8, 0.1),
            (0.24, 1.0, 0.15),
            (0.4, 0.5, 0.1),
            (0.5, 0.7, 0.1),
            (0.6, 1.0, 0.15),
        ])
    }

    /// 뻑 - 경고 진동
    func playPpukHaptic() {
        notificationFeedback(.warning)
    }

    /// 쓸 - 쓸어가는 느낌
    func playSsulHaptic() {
        guard isEnabled else { return }
        playCustomPattern(events: [
            (0.0, 0.3, 0.05),
            (0.05, 0.4, 0.05),
            (0.1, 0.5, 0.05),
            (0.15, 0.6, 0.05),
            (0.2, 0.7, 0.05),
            (0.25, 0.6, 0.05),
            (0.3, 0.4, 0.05),
        ])
    }

    /// 쪽 - 깔끔한 진동
    func playJjokHaptic() {
        impactFeedback(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.impactFeedback(.light)
        }
    }

    // MARK: - 커스텀 패턴

    /// 커스텀 햅틱 패턴 재생
    /// events: [(time, intensity, sharpness)]
    private func playCustomPattern(events: [(Double, Float, Float)]) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else {
            // Core Haptics 미지원 시 기본 진동 사용
            impactFeedback(.medium)
            return
        }

        var hapticEvents: [CHHapticEvent] = []

        for (time, eventIntensity, sharpness) in events {
            let adjustedIntensity = eventIntensity * intensity
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: adjustedIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: time
            )
            hapticEvents.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic pattern playback failed: \(error)")
        }
    }
}
