import Foundation

/// 화투 카드 종류
enum CardType: String, CaseIterable, Codable {
    case bright     // 광 (光) - 5장
    case animal     // 열끗/동물 - 9장
    case ribbon     // 띠/리본 - 10장
    case junk       // 피 - 24장
    case doubleJunk // 쌍피 (피 2장 가치)

    var displayName: String {
        switch self {
        case .bright:     return "광"
        case .animal:     return "열끗"
        case .ribbon:     return "띠"
        case .junk:       return "피"
        case .doubleJunk: return "쌍피"
        }
    }

    var emoji: String {
        switch self {
        case .bright:     return "🌟"
        case .animal:     return "🦌"
        case .ribbon:     return "🎀"
        case .junk:       return "🍃"
        case .doubleJunk: return "🍃🍃"
        }
    }

    /// 피 가치 (점수 계산용)
    var junkValue: Int {
        switch self {
        case .doubleJunk: return 2
        case .junk:       return 1
        default:          return 0
        }
    }
}

/// 띠 하위 분류
enum RibbonType: String, Codable {
    case redPoetry  // 홍단 (빨간 글씨 띠) - 1, 2, 3월
    case bluePlain  // 청단 (파란 띠) - 6, 9, 10월
    case redPlain   // 초단 (빨간 민 띠) - 4, 5, 7월
    case none       // 분류 없음

    var displayName: String {
        switch self {
        case .redPoetry: return "홍단"
        case .bluePlain: return "청단"
        case .redPlain:  return "초단"
        case .none:      return ""
        }
    }
}
