import Foundation

/// AI 전략 프로토콜
protocol AIStrategy {
    var difficulty: AIDifficulty { get }

    /// 손패에서 카드 선택 + 바닥 매칭 카드 선택 (2장 중 선택 시)
    func selectCard(state: GameState) -> (Card, Card?)

    /// 고/스톱 결정
    func shouldCallGo(state: GameState, currentScore: Int, goCount: Int) -> Bool
}

/// AI 패 평가 유틸리티
struct AIEvaluator {

    /// 카드의 전략적 가치 평가
    static func evaluateCardValue(_ card: Card, state: GameState) -> Double {
        var value: Double = 0

        switch card.type {
        case .bright:
            value = 100.0
            // 광 몇 개 모았는지에 따라 추가 가치
            let brightCount = state.aiPlayer.capturedBrights.count
            if brightCount >= 2 { value += 50 }

        case .animal:
            value = 30.0
            if card.isGodoriCard {
                let godoriCount = state.aiPlayer.godoriCards.count
                value = godoriCount >= 1 ? 60.0 : 40.0
            }

        case .ribbon:
            value = 20.0
            // 같은 종류의 띠를 몇 개 모았는지
            switch card.ribbonType {
            case .redPoetry:
                let count = state.aiPlayer.redPoetryRibbons.count
                if count >= 1 { value += Double(count) * 15.0 }
            case .bluePlain:
                let count = state.aiPlayer.bluePlainRibbons.count
                if count >= 1 { value += Double(count) * 15.0 }
            case .redPlain:
                let count = state.aiPlayer.redPlainRibbons.count
                if count >= 1 { value += Double(count) * 15.0 }
            case .none:
                break
            }

        case .doubleJunk:
            value = 8.0
            let junkCount = state.aiPlayer.totalJunkCount
            if junkCount >= 8 { value += 10.0 } // 피 10장 가까이

        case .junk:
            value = 3.0
            let junkCount = state.aiPlayer.totalJunkCount
            if junkCount >= 8 { value += 5.0 }
        }

        return value
    }

    /// 매칭으로 얻을 수 있는 총 가치
    static func evaluateMatchValue(handCard: Card, tableCard: Card, state: GameState) -> Double {
        return evaluateCardValue(handCard, state: state) + evaluateCardValue(tableCard, state: state)
    }

    /// 고/스톱 기대값 계산
    static func evaluateGoExpectedValue(state: GameState, currentScore: Int, goCount: Int) -> Double {
        let aiPlayer = state.aiPlayer
        let opponent = state.humanPlayer

        // 남은 손패 장수
        let remainingHands = aiPlayer.hand.count

        // 상대방 점수 위협도
        let opponentScore = ScoreCalculator(rules: .standard).calculateBaseScore(for: opponent)

        // 기본 기대값 계산
        var expectedGain: Double = Double(remainingHands) * 0.5 // 평균 기대 획득량

        // 위험도: 상대방이 점수 달성 가능성
        let risk = Double(opponentScore) / 7.0

        // 현재 점수가 높을수록 스톱이 유리
        let stopValue = Double(currentScore)

        // 고 가치: 추가 점수 기대값 - 리스크
        let goValue = expectedGain - (risk * stopValue)

        return goValue
    }
}
