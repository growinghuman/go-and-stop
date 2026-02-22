import Foundation

/// 카드 매칭 결과
enum MatchResult: Equatable {
    case noMatch                        // 매칭 없음 → 바닥에 놓기
    case oneMatch(Card)                 // 바닥 1장과 매칭 → 가져가기
    case twoMatch([Card])               // 바닥 2장과 매칭 → 1장 선택
    case threeMatch([Card])             // 바닥 3장과 매칭 → 3장 모두 가져가기 (뻑 풀기)
    case selfMatch                      // 같은 월 카드가 없어서 자기 카드만 바닥에 놓임
}

/// 턴 한 회의 매칭 처리 결과
struct TurnMatchResult {
    let playedCard: Card                // 내가 낸 카드
    let handMatchResult: MatchResult    // 손패 카드 매칭 결과
    let flippedCard: Card?              // 덱에서 뒤집은 카드
    let flipMatchResult: MatchResult?   // 뒤집은 카드 매칭 결과
    var capturedCards: [Card]           // 이번 턴에 획득한 카드들
    var isJjok: Bool                    // 쪽 (3장 동시 획득)
    var isSsul: Bool                    // 쓸 (바닥 전부 쓸기)
    var isPpuk: Bool                    // 뻑
}

/// 카드 매칭 로직
struct CardMatcher {

    /// 손패 카드가 바닥에서 매칭할 수 있는 카드 찾기
    static func findMatches(card: Card, tableCards: [Card]) -> MatchResult {
        let sameMonthCards = tableCards.filter { $0.month == card.month }

        switch sameMonthCards.count {
        case 0:
            return .noMatch
        case 1:
            return .oneMatch(sameMonthCards[0])
        case 2:
            return .twoMatch(sameMonthCards)
        case 3:
            return .threeMatch(sameMonthCards)
        default:
            return .noMatch
        }
    }

    /// 매칭 실행 - 카드를 바닥에 내고 매칭 처리
    static func executeHandMatch(
        playedCard: Card,
        selectedTableCard: Card?,
        tableCards: inout [Card]
    ) -> (captured: [Card], remaining: [Card]) {
        let matchResult = findMatches(card: playedCard, tableCards: tableCards)

        switch matchResult {
        case .noMatch:
            // 매칭 실패 → 바닥에 카드 놓기
            tableCards.append(playedCard)
            return (captured: [], remaining: tableCards)

        case .oneMatch(let tableCard):
            // 1장 매칭 → 둘 다 가져감
            tableCards.removeAll { $0.id == tableCard.id }
            return (captured: [playedCard, tableCard], remaining: tableCards)

        case .twoMatch(let tableMatchCards):
            // 2장 매칭 → 플레이어가 1장 선택
            if let selected = selectedTableCard, tableMatchCards.contains(where: { $0.id == selected.id }) {
                tableCards.removeAll { $0.id == selected.id }
                return (captured: [playedCard, selected], remaining: tableCards)
            }
            // 선택하지 않으면 첫 번째 카드
            let firstCard = tableMatchCards[0]
            tableCards.removeAll { $0.id == firstCard.id }
            return (captured: [playedCard, firstCard], remaining: tableCards)

        case .threeMatch(let tableMatchCards):
            // 3장 매칭 → 뻑 풀기, 4장 모두 가져감
            for card in tableMatchCards {
                tableCards.removeAll { $0.id == card.id }
            }
            return (captured: [playedCard] + tableMatchCards, remaining: tableCards)

        case .selfMatch:
            return (captured: [], remaining: tableCards)
        }
    }

    /// 덱에서 뒤집은 카드 매칭 처리
    static func executeFlipMatch(
        flippedCard: Card,
        selectedTableCard: Card?,
        tableCards: inout [Card],
        handPlayedCard: Card? // 이전에 바닥에 놓은 카드 (noMatch일 때)
    ) -> (captured: [Card], isJjok: Bool, isPpuk: Bool) {
        let matchResult = findMatches(card: flippedCard, tableCards: tableCards)
        var isJjok = false
        var isPpuk = false

        switch matchResult {
        case .noMatch:
            // 뒤집은 카드도 매칭 실패 → 바닥에 놓기
            tableCards.append(flippedCard)
            return (captured: [], isJjok: false, isPpuk: false)

        case .oneMatch(let tableCard):
            // 쪽 체크: 뒤집은 카드가 이전에 바닥에 놓은 내 카드와 같은 월인 경우
            if let handCard = handPlayedCard, handCard.month == flippedCard.month {
                // 쪽! 3장 모두 가져감
                tableCards.removeAll { $0.id == tableCard.id }
                isJjok = true
                return (captured: [flippedCard, tableCard], isJjok: true, isPpuk: false)
            }

            tableCards.removeAll { $0.id == tableCard.id }
            return (captured: [flippedCard, tableCard], isJjok: false, isPpuk: false)

        case .twoMatch(let tableMatchCards):
            // 뻑! 바닥에 같은 월 2장 + 뒤집은 카드 = 3장 → 바닥에 놓고 다음에
            // 뻑은 3장이 바닥에 쌓이는 상태
            tableCards.append(flippedCard)
            isPpuk = true
            return (captured: [], isJjok: false, isPpuk: true)

        case .threeMatch(let tableMatchCards):
            // 3장 + 뒤집은 카드 = 4장 모두 가져감 (뻑 풀기)
            for card in tableMatchCards {
                tableCards.removeAll { $0.id == card.id }
            }
            return (captured: [flippedCard] + tableMatchCards, isJjok: false, isPpuk: false)

        case .selfMatch:
            return (captured: [], isJjok: false, isPpuk: false)
        }
    }

    /// 쓸 체크: 바닥 카드가 모두 없어졌는지
    static func checkSsul(tableCards: [Card]) -> Bool {
        return tableCards.isEmpty
    }

    /// 폭탄 실행: 손에 같은 월 3장 + 바닥 1장
    static func executeBomb(
        bombCards: [Card],
        tableCard: Card,
        tableCards: inout [Card],
        opponent: Player,
        stealCount: Int
    ) -> [Card] {
        tableCards.removeAll { $0.id == tableCard.id }

        var captured = bombCards + [tableCard]

        // 상대방 피 빼앗기
        let opponentJunks = opponent.capturedCards.filter { $0.type == .junk || $0.type == .doubleJunk }
        let stealCards = Array(opponentJunks.prefix(stealCount))
        for stolen in stealCards {
            opponent.capturedCards.removeAll { $0.id == stolen.id }
            captured.append(stolen)
        }

        return captured
    }
}
