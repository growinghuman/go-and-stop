import Foundation

/// 초급 AI - 기본적인 매칭 + 약간의 랜덤
class BeginnerAI: AIStrategy {
    let difficulty: AIDifficulty = .beginner

    func selectCard(state: GameState) -> (Card, Card?) {
        let hand = state.aiPlayer.hand
        guard !hand.isEmpty else { return (hand[0], nil) }

        // 1. 매칭 가능한 카드 찾기
        var matchableCards: [(Card, MatchResult)] = []

        for card in hand {
            let result = CardMatcher.findMatches(card: card, tableCards: state.tableCards)
            switch result {
            case .noMatch:
                continue
            default:
                matchableCards.append((card, result))
            }
        }

        // 2. 매칭 가능한 카드가 있으면 랜덤 선택 (초급이니까)
        if !matchableCards.isEmpty {
            let selected = matchableCards.randomElement()!
            let tableCard: Card?

            switch selected.1 {
            case .oneMatch(let tc):
                tableCard = tc
            case .twoMatch(let tcs):
                tableCard = tcs.randomElement() // 랜덤 선택 (초급)
            case .threeMatch:
                tableCard = nil
            default:
                tableCard = nil
            }

            return (selected.0, tableCard)
        }

        // 3. 매칭 불가 → 랜덤 카드 버리기 (초급은 전략 없이)
        return (hand.randomElement()!, nil)
    }

    func shouldCallGo(state: GameState, currentScore: Int, goCount: Int) -> Bool {
        // 초급: 단순 규칙
        // 7점 이상이면 80% 확률로 스톱
        // 이미 고를 했으면 50% 확률로 스톱
        if goCount >= 2 { return false } // 2고 이상은 스톱
        if currentScore >= 10 { return false } // 10점 이상은 스톱

        return Double.random(in: 0...1) < 0.4 // 40% 확률로 고
    }
}
