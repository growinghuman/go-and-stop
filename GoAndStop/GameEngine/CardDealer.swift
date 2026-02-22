import Foundation

/// 카드 배분 담당
struct CardDealer {

    /// 2인 맞고 배분 결과
    struct DealResult {
        let playerHand: [Card]  // 선수(사람) 손패: 10장
        let aiHand: [Card]      // 후수(AI) 손패: 10장
        let tableCards: [Card]  // 바닥: 8장
        let deck: [Card]        // 나머지 덱: 20장
    }

    /// 2인 맞고 카드 배분
    /// 실제 화투와 동일하게: 바닥 4장 → 선수 5장 → 후수 5장 → 바닥 4장 → 선수 5장 → 후수 5장
    static func dealForMatchGo(shuffledDeck: [Card]? = nil) -> DealResult {
        var deck = shuffledDeck ?? Card.createShuffledDeck()

        var playerHand: [Card] = []
        var aiHand: [Card] = []
        var tableCards: [Card] = []

        // 1차: 바닥 4장
        for _ in 0..<4 { tableCards.append(deck.removeFirst()) }
        // 1차: 선수 5장
        for _ in 0..<5 { playerHand.append(deck.removeFirst()) }
        // 1차: 후수 5장
        for _ in 0..<5 { aiHand.append(deck.removeFirst()) }

        // 2차: 바닥 4장
        for _ in 0..<4 { tableCards.append(deck.removeFirst()) }
        // 2차: 선수 5장
        for _ in 0..<5 { playerHand.append(deck.removeFirst()) }
        // 2차: 후수 5장
        for _ in 0..<5 { aiHand.append(deck.removeFirst()) }

        // 월 기준으로 정렬
        playerHand.sort { $0.month.rawValue < $1.month.rawValue }
        aiHand.sort { $0.month.rawValue < $1.month.rawValue }

        return DealResult(
            playerHand: playerHand,
            aiHand: aiHand,
            tableCards: tableCards,
            deck: deck // 나머지 20장
        )
    }

    /// 바닥 초기 상태 확인 - 같은 월 4장이 바닥에 있으면 자동 처리
    struct InitialTableCheck {
        let processedTableCards: [Card]
        let bonusCards: [(PlayerID, [Card])] // 선수에게 돌아가는 보너스 카드
        let events: [String]
    }

    static func checkInitialTable(tableCards: [Card], dealerID: PlayerID) -> InitialTableCheck {
        var processed = tableCards
        var bonusCards: [(PlayerID, [Card])] = []
        var events: [String] = []

        // 같은 월 4장이 바닥에 있으면 → 딜러(선수)가 가져감
        let grouped = Dictionary(grouping: processed) { $0.month }
        for (month, cards) in grouped {
            if cards.count == 4 {
                bonusCards.append((dealerID, cards))
                processed.removeAll { $0.month == month }
                events.append("바닥에 \(month.shortName) 4장 → \(dealerID.displayName)이(가) 획득")
            } else if cards.count == 3 {
                // 같은 월 3장이 바닥에 있으면 한 묶음으로 (뻑 상태)
                events.append("바닥에 \(month.shortName) 3장 → 뻑 가능")
            }
        }

        return InitialTableCheck(
            processedTableCards: processed,
            bonusCards: bonusCards,
            events: events
        )
    }

    /// 손패에서 흔듦/폭탄 가능한 카드 확인
    struct HandSpecialCheck {
        let shakeMonths: [CardMonth]    // 같은 월 3장 (흔듦 가능)
        let bombMonths: [CardMonth]     // 같은 월 4장 (총통 가능)
    }

    static func checkHandSpecials(hand: [Card]) -> HandSpecialCheck {
        let grouped = Dictionary(grouping: hand) { $0.month }
        var shakeMonths: [CardMonth] = []
        var bombMonths: [CardMonth] = []

        for (month, cards) in grouped {
            if cards.count == 4 {
                bombMonths.append(month)
            } else if cards.count == 3 {
                shakeMonths.append(month)
            }
        }

        return HandSpecialCheck(shakeMonths: shakeMonths, bombMonths: bombMonths)
    }
}
