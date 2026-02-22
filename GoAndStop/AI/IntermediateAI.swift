import Foundation

/// 중급 AI - 전략적 카드 선택 + 확률 기반 판단
class IntermediateAI: AIStrategy {
    let difficulty: AIDifficulty = .intermediate

    func selectCard(state: GameState) -> (Card, Card?) {
        let hand = state.aiPlayer.hand
        guard !hand.isEmpty else { return (hand[0], nil) }

        // 모든 가능한 플레이를 평가
        var bestPlay: (card: Card, tableCard: Card?, score: Double) = (hand[0], nil, -1000)

        for card in hand {
            let matchResult = CardMatcher.findMatches(card: card, tableCards: state.tableCards)

            switch matchResult {
            case .noMatch:
                // 버릴 때: 카드 가치가 낮을수록 좋음
                let discardScore = -AIEvaluator.evaluateCardValue(card, state: state)
                if discardScore > bestPlay.score {
                    bestPlay = (card, nil, discardScore)
                }

            case .oneMatch(let tableCard):
                let matchScore = evaluateMatch(handCard: card, tableCard: tableCard, state: state)
                if matchScore > bestPlay.score {
                    bestPlay = (card, tableCard, matchScore)
                }

            case .twoMatch(let tableCards):
                // 2장 중 더 좋은 걸 선택
                for tableCard in tableCards {
                    let matchScore = evaluateMatch(handCard: card, tableCard: tableCard, state: state)
                    if matchScore > bestPlay.score {
                        bestPlay = (card, tableCard, matchScore)
                    }
                }

            case .threeMatch:
                // 4장 모두 먹기 - 항상 좋음
                let score = AIEvaluator.evaluateCardValue(card, state: state) * 3
                if score > bestPlay.score {
                    bestPlay = (card, nil, score)
                }

            case .selfMatch:
                break
            }
        }

        return (bestPlay.card, bestPlay.tableCard)
    }

    func shouldCallGo(state: GameState, currentScore: Int, goCount: Int) -> Bool {
        // 최대 고 횟수 제한
        if goCount >= 3 { return false }

        let expectedValue = AIEvaluator.evaluateGoExpectedValue(
            state: state,
            currentScore: currentScore,
            goCount: goCount
        )

        // 상대 점수 체크
        let opponentScore = ScoreCalculator(rules: .standard).calculateBaseScore(for: state.humanPlayer)

        // 상대가 스톱 가능할 정도로 점수가 높으면 위험
        if opponentScore >= 5 && goCount >= 1 {
            return false
        }

        // 점수별 고/스톱 기준
        switch currentScore {
        case 7...8:
            // 낮은 점수 → 고 유리
            return goCount < 2 && expectedValue > -5
        case 9...11:
            // 중간 점수 → 상황 판단
            return goCount < 1 && expectedValue > 0
        case 12...15:
            // 높은 점수 → 보수적
            return goCount == 0 && expectedValue > 3
        default:
            // 매우 높은 점수 → 스톱
            return false
        }
    }

    // MARK: - 매칭 평가

    private func evaluateMatch(handCard: Card, tableCard: Card, state: GameState) -> Double {
        var score = AIEvaluator.evaluateMatchValue(handCard: handCard, tableCard: tableCard, state: state)

        // 전략적 보너스

        // 광 카드 먹기 보너스
        if tableCard.isBright {
            score += 80
        }

        // 고도리 완성 가능성
        if tableCard.isGodoriCard {
            let currentGodori = state.aiPlayer.godoriCards.count
            if currentGodori >= 2 {
                score += 100 // 고도리 완성!
            } else if currentGodori >= 1 {
                score += 30
            }
        }

        // 띠 세트 완성 가능성
        if tableCard.type == .ribbon {
            switch tableCard.ribbonType {
            case .redPoetry:
                let count = state.aiPlayer.redPoetryRibbons.count
                if count >= 2 { score += 80 }
                else if count >= 1 { score += 20 }
            case .bluePlain:
                let count = state.aiPlayer.bluePlainRibbons.count
                if count >= 2 { score += 80 }
                else if count >= 1 { score += 20 }
            case .redPlain:
                let count = state.aiPlayer.redPlainRibbons.count
                if count >= 2 { score += 80 }
                else if count >= 1 { score += 20 }
            case .none:
                break
            }
        }

        // 상대방 광 차단
        if tableCard.isBright {
            let opponentBrights = state.humanPlayer.capturedBrights.count
            if opponentBrights >= 2 {
                score += 60 // 상대 삼광 방지
            }
        }

        // 피 10장 가까이 → 피 먹기 보너스
        let junkCount = state.aiPlayer.totalJunkCount
        if junkCount >= 8 && (tableCard.type == .junk || tableCard.type == .doubleJunk) {
            score += 15
        }

        return score
    }
}
