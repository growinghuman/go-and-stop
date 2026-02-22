import Foundation

/// 앱스토어 제출용 메타데이터
enum AppStoreMetadata {

    // MARK: - 기본 정보

    static let appName = "맞고 - Go & Stop"
    static let subtitle = "한국 전통 화투 카드 게임"
    static let bundleID = "com.goandstop.matchgo"
    static let category = "Games"
    static let subcategory = "Card"
    static let ageRating = "12+"  // 시뮬레이션 도박
    static let price = "Free"

    // MARK: - 앱 설명 (한국어)

    static let descriptionKR = """
    🎴 맞고 - 최고의 한국 전통 화투 게임!

    화려한 연출과 실감나는 사운드로 즐기는 정통 맞고!
    48장의 아름다운 화투 카드로 전략적인 카드 배틀을 즐겨보세요.

    ◆ 게임 특징
    ▸ 정통 2인 맞고 룰 완벽 구현
    ▸ 3단계 AI 난이도 (초급 / 중급 / 고급)
    ▸ 화려한 이펙트 & 실감나는 사운드
    ▸ 햅틱(진동) 피드백으로 손맛 극대화
    ▸ 오프라인 완벽 지원 - 인터넷 없이 플레이

    ◆ 완전한 맞고 규칙
    ▸ 광 (오광, 비광, 삼광)
    ▸ 띠 (홍단, 청단, 초단)
    ▸ 열끗 & 피 점수
    ▸ 고도리, 쓸, 쪽, 뻑, 폭탄, 흔듦
    ▸ 고/스톱 전략적 선택
    ▸ 광박, 피박, 멍박 배수

    ◆ 고급 AI
    ▸ 초급: 입문자를 위한 친절한 AI
    ▸ 중급: 전략적 카드 선택
    ▸ 고급: Monte Carlo 시뮬레이션 기반 최적 플레이

    ◆ 화려한 연출
    ▸ 전통 화투 스타일 고해상도 카드
    ▸ 광 획득, 고도리, 폭탄 등 화려한 이펙트
    ▸ 국악풍 BGM (궁상각치우 펜타토닉)
    ▸ 승리/패배 실감 사운드

    ◆ 통계 & 기록
    ▸ 전적 관리 (승률, 최고 점수)
    ▸ 업적 달성
    ▸ Game Center 리더보드

    지금 바로 다운로드하고 맞고의 재미를 느껴보세요! 🔥
    """

    // MARK: - 앱 설명 (영어)

    static let descriptionEN = """
    🎴 MatchGo - The Best Korean Hwatu Card Game!

    Enjoy the authentic Korean Go-Stop (Matgo) card game with stunning effects and realistic sounds!
    Experience strategic card battles with 48 beautiful Hwatu cards.

    ◆ Features
    ▸ Authentic 2-player Matgo rules
    ▸ 3 AI difficulty levels (Beginner / Intermediate / Expert)
    ▸ Gorgeous visual effects & immersive sound
    ▸ Haptic feedback for tactile experience
    ▸ Full offline support - play anywhere

    ◆ Complete Matgo Rules
    ▸ Bright cards (5-Bright, Rain-Bright, 3-Bright)
    ▸ Ribbon sets (Red Poetry, Blue Plain, Red Plain)
    ▸ Animal & Junk card scoring
    ▸ Godori, Ssul, Jjok, Ppuk, Bomb, Shake
    ▸ Strategic Go/Stop decisions
    ▸ Score multipliers (Gwangbak, Pibak, Meongbak)

    ◆ Advanced AI
    ▸ Beginner: Friendly AI for newcomers
    ▸ Intermediate: Strategic card selection
    ▸ Expert: Monte Carlo simulation-based optimal play

    Download now and experience the thrill of MatchGo! 🔥
    """

    // MARK: - 키워드

    static let keywordsKR = "화투, 맞고, 고스톱, 카드게임, 한국게임, 전통게임, 화투게임, 맞고게임"
    static let keywordsEN = "hwatu, matgo, go-stop, gostop, korean card game, hanafuda, card game"

    // MARK: - 프로모션 텍스트

    static let promotionalTextKR = "🎴 정통 맞고를 화려한 연출과 함께! AI 3단계 난이도로 초보부터 고수까지!"
    static let promotionalTextEN = "🎴 Authentic Korean Matgo with stunning effects! 3 AI difficulty levels!"

    // MARK: - What's New

    static let whatsNewKR = """
    v1.0.0 - 첫 출시!
    ▸ 정통 2인 맞고 게임
    ▸ 3단계 AI (초급/중급/고급)
    ▸ 화려한 이펙트 & 사운드
    ▸ 햅틱 피드백
    ▸ 전적 통계 & Game Center
    """

    // MARK: - 지원 URL

    static let supportURL = "https://github.com/goandstop-game/support"
    static let privacyPolicyURL = "https://github.com/goandstop-game/privacy-policy"

    // MARK: - 스크린샷 설명

    static let screenshotCaptions: [String] = [
        "화려한 메인 화면",
        "실감나는 게임 플레이",
        "고/스톱 전략적 선택",
        "화려한 승리 연출",
        "상세한 통계 & 전적",
        "쉬운 규칙 설명서"
    ]
}
