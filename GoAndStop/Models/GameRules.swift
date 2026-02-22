import Foundation

/// 게임 규칙 설정 (커스터마이징 가능)
struct GameRules: Codable {
    /// 스톱 가능 최소 점수 (맞고: 보통 7점)
    var minimumScoreToStop: Int = 7

    /// 최대 고 횟수 (0 = 무제한)
    var maxGoCount: Int = 0

    /// 폭탄 시 상대 피 빼앗기 장수
    var bombStealJunkCount: Int = 1

    /// 총통 룰 적용 여부
    var enableChongTong: Bool = true

    /// 흔듦 룰 적용 여부
    var enableShake: Bool = true

    /// 나가리 시 다음 판 배수 적용
    var nagariDoubles: Bool = true

    /// 비삼광 점수 (2점 또는 3점)
    var rainThreeBrightScore: Int = 2

    /// 오광 점수
    var fiveBrightScore: Int = 15

    /// 고도리 점수 (3점 또는 5점)
    var godoriScore: Int = 5

    /// 광박 적용 방식 (true: 배수, false: +1점)
    var brightPenaltyIsMultiplier: Bool = false

    /// 피박 라인 (이 수 이하면 피박)
    var junkPenaltyThreshold: Int = 7

    /// 멍박 (열끗 0장) 적용 여부
    var enableAnimalPenalty: Bool = true

    /// 독박 (3인전 전용) 적용 여부
    var enableSoloPenalty: Bool = false

    /// AI 난이도
    var aiDifficulty: AIDifficulty = .intermediate

    /// 게임 속도 배수 (1.0 = 보통)
    var gameSpeed: Double = 1.0

    /// 기본 룰셋
    static let standard = GameRules()

    /// 빠른 게임 (3점 스톱)
    static let quickGame: GameRules = {
        var rules = GameRules()
        rules.minimumScoreToStop = 3
        rules.gameSpeed = 1.5
        return rules
    }()
}

/// AI 난이도
enum AIDifficulty: String, CaseIterable, Codable {
    case beginner     = "초급"
    case intermediate = "중급"
    case expert       = "고급"

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .beginner:     return "입문자용 - 기본적인 매칭만 수행"
        case .intermediate: return "중급자용 - 전략적 카드 선택"
        case .expert:       return "고급자용 - 확률 기반 최적 플레이"
        }
    }
}
