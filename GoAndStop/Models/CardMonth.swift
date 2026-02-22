import Foundation

/// 화투 12개월 - 각 월별 꽃과 테마
enum CardMonth: Int, CaseIterable, Comparable, Codable {
    case january = 1    // 송학 (松鶴) - 소나무와 학
    case february       // 매조 (梅鳥) - 매화와 꾀꼬리
    case march          // 벚꽃 (桜) - 벚꽃과 커튼
    case april          // 흑싸리 - 등나무와 두견새
    case may            // 난초 (蘭) - 난초와 다리
    case june           // 목단 (牧丹) - 모란과 나비
    case july           // 홍싸리 - 싸리와 멧돼지
    case august         // 공산 (空山) - 억새와 달/기러기
    case september      // 국진 (菊) - 국화와 술잔
    case october        // 단풍 (丹楓) - 단풍과 사슴
    case november       // 오동 (梧桐) - 오동나무
    case december       // 비 (雨) - 비와 버드나무

    var name: String {
        switch self {
        case .january:   return "1월 송학"
        case .february:  return "2월 매조"
        case .march:     return "3월 벚꽃"
        case .april:     return "4월 흑싸리"
        case .may:       return "5월 난초"
        case .june:      return "6월 목단"
        case .july:      return "7월 홍싸리"
        case .august:    return "8월 공산"
        case .september: return "9월 국진"
        case .october:   return "10월 단풍"
        case .november:  return "11월 오동"
        case .december:  return "12월 비"
        }
    }

    var flower: String {
        switch self {
        case .january:   return "소나무"
        case .february:  return "매화"
        case .march:     return "벚꽃"
        case .april:     return "등나무"
        case .may:       return "난초"
        case .june:      return "모란"
        case .july:      return "싸리"
        case .august:    return "억새"
        case .september: return "국화"
        case .october:   return "단풍"
        case .november:  return "오동"
        case .december:  return "버드나무"
        }
    }

    var shortName: String {
        return "\(rawValue)월"
    }

    static func < (lhs: CardMonth, rhs: CardMonth) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
