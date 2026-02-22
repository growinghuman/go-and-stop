import Foundation

/// 화투 카드 한 장을 표현하는 모델
struct Card: Identifiable, Hashable, Codable {
    let id: String
    let month: CardMonth
    let type: CardType
    let ribbonType: RibbonType
    let name: String
    let imageName: String
    let index: Int // 같은 월 내 카드 순서 (0~3)

    /// 광 카드인지 여부
    var isBright: Bool { type == .bright }

    /// 비광(12월 광)인지 여부
    var isRainBright: Bool { month == .december && type == .bright }

    /// 고도리 구성 카드인지 (2월 꾀꼬리, 4월 두견, 8월 기러기)
    var isGodoriCard: Bool {
        guard type == .animal else { return false }
        return month == .february || month == .april || month == .august
    }

    /// 피 가치 (쌍피=2, 일반피=1, 나머지=0)
    var junkValue: Int { type.junkValue }

    /// 카드 뒷면 이미지 이름
    static let backImageName = "card_back"

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 전체 화투덱 생성
extension Card {
    /// 48장 표준 화투덱 생성
    static func createDeck() -> [Card] {
        var deck: [Card] = []

        // 1월 - 송학
        deck.append(Card(id: "jan_bright", month: .january, type: .bright, ribbonType: .none,
                         name: "송학 광", imageName: "card_01_bright", index: 0))
        deck.append(Card(id: "jan_ribbon", month: .january, type: .ribbon, ribbonType: .redPoetry,
                         name: "송학 홍단", imageName: "card_01_ribbon", index: 1))
        deck.append(Card(id: "jan_junk1", month: .january, type: .junk, ribbonType: .none,
                         name: "송학 피1", imageName: "card_01_junk1", index: 2))
        deck.append(Card(id: "jan_junk2", month: .january, type: .junk, ribbonType: .none,
                         name: "송학 피2", imageName: "card_01_junk2", index: 3))

        // 2월 - 매조
        deck.append(Card(id: "feb_animal", month: .february, type: .animal, ribbonType: .none,
                         name: "매조 꾀꼬리", imageName: "card_02_animal", index: 0))
        deck.append(Card(id: "feb_ribbon", month: .february, type: .ribbon, ribbonType: .redPoetry,
                         name: "매조 홍단", imageName: "card_02_ribbon", index: 1))
        deck.append(Card(id: "feb_junk1", month: .february, type: .junk, ribbonType: .none,
                         name: "매조 피1", imageName: "card_02_junk1", index: 2))
        deck.append(Card(id: "feb_junk2", month: .february, type: .junk, ribbonType: .none,
                         name: "매조 피2", imageName: "card_02_junk2", index: 3))

        // 3월 - 벚꽃
        deck.append(Card(id: "mar_bright", month: .march, type: .bright, ribbonType: .none,
                         name: "벚꽃 커튼 광", imageName: "card_03_bright", index: 0))
        deck.append(Card(id: "mar_ribbon", month: .march, type: .ribbon, ribbonType: .redPoetry,
                         name: "벚꽃 홍단", imageName: "card_03_ribbon", index: 1))
        deck.append(Card(id: "mar_junk1", month: .march, type: .junk, ribbonType: .none,
                         name: "벚꽃 피1", imageName: "card_03_junk1", index: 2))
        deck.append(Card(id: "mar_junk2", month: .march, type: .junk, ribbonType: .none,
                         name: "벚꽃 피2", imageName: "card_03_junk2", index: 3))

        // 4월 - 흑싸리
        deck.append(Card(id: "apr_animal", month: .april, type: .animal, ribbonType: .none,
                         name: "흑싸리 두견새", imageName: "card_04_animal", index: 0))
        deck.append(Card(id: "apr_ribbon", month: .april, type: .ribbon, ribbonType: .redPlain,
                         name: "흑싸리 초단", imageName: "card_04_ribbon", index: 1))
        deck.append(Card(id: "apr_junk1", month: .april, type: .junk, ribbonType: .none,
                         name: "흑싸리 피1", imageName: "card_04_junk1", index: 2))
        deck.append(Card(id: "apr_junk2", month: .april, type: .junk, ribbonType: .none,
                         name: "흑싸리 피2", imageName: "card_04_junk2", index: 3))

        // 5월 - 난초
        deck.append(Card(id: "may_animal", month: .may, type: .animal, ribbonType: .none,
                         name: "난초 다리", imageName: "card_05_animal", index: 0))
        deck.append(Card(id: "may_ribbon", month: .may, type: .ribbon, ribbonType: .redPlain,
                         name: "난초 초단", imageName: "card_05_ribbon", index: 1))
        deck.append(Card(id: "may_junk1", month: .may, type: .junk, ribbonType: .none,
                         name: "난초 피1", imageName: "card_05_junk1", index: 2))
        deck.append(Card(id: "may_junk2", month: .may, type: .junk, ribbonType: .none,
                         name: "난초 피2", imageName: "card_05_junk2", index: 3))

        // 6월 - 목단
        deck.append(Card(id: "jun_animal", month: .june, type: .animal, ribbonType: .none,
                         name: "목단 나비", imageName: "card_06_animal", index: 0))
        deck.append(Card(id: "jun_ribbon", month: .june, type: .ribbon, ribbonType: .bluePlain,
                         name: "목단 청단", imageName: "card_06_ribbon", index: 1))
        deck.append(Card(id: "jun_junk1", month: .june, type: .junk, ribbonType: .none,
                         name: "목단 피1", imageName: "card_06_junk1", index: 2))
        deck.append(Card(id: "jun_junk2", month: .june, type: .junk, ribbonType: .none,
                         name: "목단 피2", imageName: "card_06_junk2", index: 3))

        // 7월 - 홍싸리
        deck.append(Card(id: "jul_animal", month: .july, type: .animal, ribbonType: .none,
                         name: "홍싸리 멧돼지", imageName: "card_07_animal", index: 0))
        deck.append(Card(id: "jul_ribbon", month: .july, type: .ribbon, ribbonType: .redPlain,
                         name: "홍싸리 초단", imageName: "card_07_ribbon", index: 1))
        deck.append(Card(id: "jul_junk1", month: .july, type: .junk, ribbonType: .none,
                         name: "홍싸리 피1", imageName: "card_07_junk1", index: 2))
        deck.append(Card(id: "jul_junk2", month: .july, type: .junk, ribbonType: .none,
                         name: "홍싸리 피2", imageName: "card_07_junk2", index: 3))

        // 8월 - 공산
        deck.append(Card(id: "aug_bright", month: .august, type: .bright, ribbonType: .none,
                         name: "공산 달 광", imageName: "card_08_bright", index: 0))
        deck.append(Card(id: "aug_animal", month: .august, type: .animal, ribbonType: .none,
                         name: "공산 기러기", imageName: "card_08_animal", index: 1))
        deck.append(Card(id: "aug_junk1", month: .august, type: .junk, ribbonType: .none,
                         name: "공산 피1", imageName: "card_08_junk1", index: 2))
        deck.append(Card(id: "aug_junk2", month: .august, type: .junk, ribbonType: .none,
                         name: "공산 피2", imageName: "card_08_junk2", index: 3))

        // 9월 - 국진
        deck.append(Card(id: "sep_animal", month: .september, type: .animal, ribbonType: .none,
                         name: "국진 술잔", imageName: "card_09_animal", index: 0))
        deck.append(Card(id: "sep_ribbon", month: .september, type: .ribbon, ribbonType: .bluePlain,
                         name: "국진 청단", imageName: "card_09_ribbon", index: 1))
        deck.append(Card(id: "sep_junk1", month: .september, type: .junk, ribbonType: .none,
                         name: "국진 피1", imageName: "card_09_junk1", index: 2))
        deck.append(Card(id: "sep_junk2", month: .september, type: .junk, ribbonType: .none,
                         name: "국진 피2", imageName: "card_09_junk2", index: 3))

        // 10월 - 단풍
        deck.append(Card(id: "oct_animal", month: .october, type: .animal, ribbonType: .none,
                         name: "단풍 사슴", imageName: "card_10_animal", index: 0))
        deck.append(Card(id: "oct_ribbon", month: .october, type: .ribbon, ribbonType: .bluePlain,
                         name: "단풍 청단", imageName: "card_10_ribbon", index: 1))
        deck.append(Card(id: "oct_junk1", month: .october, type: .junk, ribbonType: .none,
                         name: "단풍 피1", imageName: "card_10_junk1", index: 2))
        deck.append(Card(id: "oct_junk2", month: .october, type: .junk, ribbonType: .none,
                         name: "단풍 피2", imageName: "card_10_junk2", index: 3))

        // 11월 - 오동
        deck.append(Card(id: "nov_bright", month: .november, type: .bright, ribbonType: .none,
                         name: "오동 광", imageName: "card_11_bright", index: 0))
        deck.append(Card(id: "nov_junk1", month: .november, type: .doubleJunk, ribbonType: .none,
                         name: "오동 쌍피", imageName: "card_11_double", index: 1))
        deck.append(Card(id: "nov_junk2", month: .november, type: .junk, ribbonType: .none,
                         name: "오동 피1", imageName: "card_11_junk1", index: 2))
        deck.append(Card(id: "nov_junk3", month: .november, type: .junk, ribbonType: .none,
                         name: "오동 피2", imageName: "card_11_junk2", index: 3))

        // 12월 - 비
        deck.append(Card(id: "dec_bright", month: .december, type: .bright, ribbonType: .none,
                         name: "비 광", imageName: "card_12_bright", index: 0))
        deck.append(Card(id: "dec_animal", month: .december, type: .animal, ribbonType: .none,
                         name: "비 제비", imageName: "card_12_animal", index: 1))
        deck.append(Card(id: "dec_junk1", month: .december, type: .doubleJunk, ribbonType: .none,
                         name: "비 쌍피", imageName: "card_12_double", index: 2))
        deck.append(Card(id: "dec_junk2", month: .december, type: .junk, ribbonType: .none,
                         name: "비 피", imageName: "card_12_junk", index: 3))

        return deck
    }

    /// 셔플된 덱 생성
    static func createShuffledDeck() -> [Card] {
        return createDeck().shuffled()
    }
}

// MARK: - CustomStringConvertible
extension Card: CustomStringConvertible {
    var description: String {
        return "[\(month.shortName) \(type.displayName)] \(name)"
    }
}
