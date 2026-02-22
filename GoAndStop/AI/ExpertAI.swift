import Foundation

/// 고급 AI - Monte Carlo 시뮬레이션 기반 의사결정
class ExpertAI: AIStrategy {
    let difficulty: AIDifficulty = .expert

    /// 시뮬레이션 횟수 (높을수록 정확하지만 느림)
    private let simulationCount = 200
    private let scoreCalc = ScoreCalculator(rules: .standard)

    func selectCard(state: GameState) -> (Card, Card?) {
        let hand = state.aiPlayer.hand
        guard !hand.isEmpty else { return (hand[0], nil) }

        var bestPlay: (card: Card, tableCard: Card?, expectedValue: Double) = (hand[0], nil, -Double.infinity)

        for card in hand {
            let matchResult = CardMatcher.findMatches(card: card, tableCards: state.tableCards)

            switch matchResult {
            case .noMatch:
                let ev = evaluateDiscard(card: card, state: state)
                if ev > bestPlay.expectedValue {
                    bestPlay = (card, nil, ev)
                }

            case .oneMatch(let tableCard):
                let ev = evaluateMatch(handCard: card, tableCards: [tableCard], state: state)
                if ev > bestPlay.expectedValue {
                    bestPlay = (card, tableCard, ev)
                }

            case .twoMatch(let tableCards):
                for tableCard in tableCards {
                    let ev = evaluateMatch(handCard: card, tableCards: [tableCard], state: state)
                    if ev > bestPlay.expectedValue {
                        bestPlay = (card, tableCard, ev)
                    }
                }

            case .threeMatch(let tableCards):
                let ev = evaluateMatch(handCard: card, tableCards: tableCards, state: state) * 1.5
                if ev > bestPlay.expectedValue {
                    bestPlay = (card, nil, ev)
                }

            case .selfMatch:
                break
            }
        }

        return (bestPlay.card, bestPlay.tableCard)
    }

    func shouldCallGo(state: GameState, currentScore: Int, goCount: Int) -> Bool {
        if goCount >= 4 { return false }

        // Monte Carlo 시뮬레이션으로 고/스톱 결정
        let goEV = simulateGoExpectedValue(state: state, goCount: goCount)
        let stopValue = Double(currentScore)

        // 고 보너스 반영
        let goBonus: Double
        if goCount < 2 {
            goBonus = Double(goCount + 1)
        } else {
            goBonus = stopValue * 0.5 // 3고 이상 시 배수 효과
        }

        let adjustedGoEV = goEV + goBonus

        // 상대방 위험도 평가
        let opponentThreat = evaluateOpponentThreat(state: state)

        // 최종 결정: 기대값 > 현재 확정 + 위험보정
        return adjustedGoEV > (stopValue + opponentThreat * 3.0)
    }

    // MARK: - 매칭 평가

    private func evaluateMatch(handCard: Card, tableCards: [Card], state: GameState) -> Double {
        var value: Double = 0

        let allCaptured = [handCard] + tableCards

        // 기본 카드 가치
        for card in allCaptured {
            value += cardStrategicValue(card, state: state)
        }

        // 시너지 보너스: 세트 완성에 기여하는지
        value += syngergyBonus(captured: allCaptured, state: state)

        // 상대방 차단 가치
        value += blockingValue(captured: allCaptured, state: state)

        // 덱에서 뒤집을 카드 기대값 (확률적)
        value += flipExpectedValue(afterPlaying: handCard, state: state)

        return value
    }

    private func evaluateDiscard(card: Card, state: GameState) -> Double {
        // 버리는 카드의 전략적 가치 (낮을수록 좋은 버리기)
        var value = -cardStrategicValue(card, state: state)

        // 상대에게 도움이 되는지 평가
        let opponentValue = cardValueForOpponent(card, state: state)
        value -= opponentValue * 0.5

        // 같은 월 카드가 바닥에 이미 있으면 나중에 먹힐 수 있어 덜 나쁨
        let sameMonthOnTable = state.tableCards.filter { $0.month == card.month }.count
        if sameMonthOnTable > 0 {
            value += 5.0
        }

        return value
    }

    // MARK: - 카드 전략적 가치

    private func cardStrategicValue(_ card: Card, state: GameState) -> Double {
        let ai = state.aiPlayer

        switch card.type {
        case .bright:
            let brightCount = ai.capturedBrights.count
            switch brightCount {
            case 0: return 40.0
            case 1: return 60.0
            case 2: return 120.0  // 삼광 눈앞!
            case 3: return 150.0  // 사광 눈앞!
            case 4: return 200.0  // 오광!
            default: return 40.0
            }

        case .animal:
            var value = 25.0
            if card.isGodoriCard {
                let godoriCount = ai.godoriCards.count
                switch godoriCount {
                case 0: value = 35.0
                case 1: value = 55.0
                case 2: value = 120.0 // 고도리 완성!
                default: value = 35.0
                }
            }
            // 열끗 5장 가까이
            let animalCount = ai.capturedAnimals.count
            if animalCount >= 3 { value += 10.0 }
            if animalCount >= 4 { value += 20.0 }
            return value

        case .ribbon:
            var value = 18.0
            // 같은 종류의 띠 세트 진행도
            let (setCount, _) = ribbonSetProgress(card.ribbonType, player: ai)
            switch setCount {
            case 0: value = 18.0
            case 1: value = 35.0
            case 2: value = 100.0 // 세트 완성!
            default: value = 18.0
            }
            // 띠 총 수 보너스
            let totalRibbons = ai.capturedRibbons.count
            if totalRibbons >= 3 { value += 8.0 }
            if totalRibbons >= 4 { value += 15.0 }
            return value

        case .doubleJunk:
            var value = 8.0
            let junkCount = ai.totalJunkCount
            if junkCount >= 6 { value += 5.0 }
            if junkCount >= 8 { value += 12.0 } // 피 10장 가까이
            return value

        case .junk:
            var value = 3.0
            let junkCount = ai.totalJunkCount
            if junkCount >= 6 { value += 3.0 }
            if junkCount >= 8 { value += 8.0 }
            return value
        }
    }

    // MARK: - 시너지 보너스

    private func syngergyBonus(captured: [Card], state: GameState) -> Double {
        var bonus: Double = 0
        let ai = state.aiPlayer

        for card in captured {
            // 광 세트 진행
            if card.isBright {
                let afterCount = ai.capturedBrights.count + 1
                if afterCount == 3 { bonus += 30 } // 삼광 완성
                if afterCount == 4 { bonus += 40 }
                if afterCount == 5 { bonus += 100 }
            }

            // 고도리 진행
            if card.isGodoriCard {
                let afterCount = ai.godoriCards.count + captured.filter({ $0.isGodoriCard }).count
                if afterCount >= 3 { bonus += 50 }
            }

            // 띠 세트 진행
            if card.type == .ribbon {
                let (current, _) = ribbonSetProgress(card.ribbonType, player: ai)
                let newFromCapture = captured.filter { $0.ribbonType == card.ribbonType }.count
                if current + newFromCapture >= 3 { bonus += 40 }
            }
        }

        return bonus
    }

    // MARK: - 상대 차단 가치

    private func blockingValue(captured: [Card], state: GameState) -> Double {
        var value: Double = 0
        let opponent = state.humanPlayer

        for card in captured {
            // 상대 광 세트 차단
            if card.isBright && opponent.capturedBrights.count >= 2 {
                value += 40.0
            }

            // 상대 고도리 차단
            if card.isGodoriCard && opponent.godoriCards.count >= 2 {
                value += 35.0
            }

            // 상대 띠 세트 차단
            if card.type == .ribbon {
                let (opponentCount, _) = ribbonSetProgress(card.ribbonType, player: opponent)
                if opponentCount >= 2 { value += 30.0 }
            }
        }

        return value
    }

    // MARK: - 상대 카드 가치

    private func cardValueForOpponent(_ card: Card, state: GameState) -> Double {
        let opponent = state.humanPlayer

        if card.isBright && opponent.capturedBrights.count >= 2 { return 50.0 }
        if card.isGodoriCard && opponent.godoriCards.count >= 2 { return 40.0 }
        if card.type == .ribbon {
            let (count, _) = ribbonSetProgress(card.ribbonType, player: opponent)
            if count >= 2 { return 35.0 }
        }

        return 0
    }

    // MARK: - 덱 플립 기대값

    private func flipExpectedValue(afterPlaying card: Card, state: GameState) -> Double {
        // 남은 카드에서 같은 월이 나올 확률
        let remainingDeck = state.deck
        let knownCards = Set(
            state.humanPlayer.hand.map(\.id) +
            state.aiPlayer.hand.map(\.id) +
            state.tableCards.map(\.id) +
            state.humanPlayer.capturedCards.map(\.id) +
            state.aiPlayer.capturedCards.map(\.id)
        )

        // 바닥에 놓인 카드의 월별 분포로 좋은 플립이 나올 확률 추정
        let tableMonths = state.tableCards.map(\.month)
        let uniqueMonths = Set(tableMonths)

        var expectedValue: Double = 0
        for month in uniqueMonths {
            let tableCount = tableMonths.filter({ $0 == month }).count
            // 매칭 가능한 카드가 덱에 있을 확률 추정
            let deckCount = remainingDeck.count
            if deckCount > 0 {
                let sameMonthInDeck = remainingDeck.filter({ $0.month == month }).count
                let probability = Double(sameMonthInDeck) / Double(deckCount)
                if tableCount == 1 {
                    expectedValue += probability * 10.0 // 매칭 성공
                } else if tableCount == 3 {
                    expectedValue += probability * 25.0 // 뻑 풀기
                }
            }
        }

        return expectedValue
    }

    // MARK: - Monte Carlo 고/스톱 시뮬레이션

    private func simulateGoExpectedValue(state: GameState, goCount: Int) -> Double {
        var totalScore: Double = 0

        for _ in 0..<simulationCount {
            totalScore += simulateOneGame(state: state)
        }

        return totalScore / Double(simulationCount)
    }

    /// 현재 상태에서 남은 게임을 시뮬레이션
    private func simulateOneGame(state: GameState) -> Double {
        // 간단한 시뮬레이션: 남은 턴 수만큼 랜덤 매칭
        let remainingTurns = state.aiPlayer.hand.count
        var simulatedJunkGain = 0
        var simulatedAnimalGain = 0
        var simulatedBrightGain = 0

        for _ in 0..<remainingTurns {
            // 50% 확률로 카드 매칭 성공
            if Double.random(in: 0...1) < 0.55 {
                // 매칭된 카드 타입 (확률 기반)
                let roll = Double.random(in: 0...1)
                if roll < 0.5 { simulatedJunkGain += 2 }       // 피 2장
                else if roll < 0.7 { simulatedAnimalGain += 1 } // 열끗
                else if roll < 0.9 { simulatedJunkGain += 1 }   // 피 1장
                else { simulatedBrightGain += 1 }                // 광 (드물게)
            }
        }

        // 시뮬레이션 결과로 추정 점수 계산
        let currentScore = scoreCalc.calculateBaseScore(for: state.aiPlayer)
        var additionalScore = 0

        // 추가 피 점수
        let totalJunk = state.aiPlayer.totalJunkCount + simulatedJunkGain
        if totalJunk >= 10 { additionalScore += max(0, totalJunk - 9 - max(0, state.aiPlayer.totalJunkCount - 9)) }

        // 추가 열끗 점수
        let totalAnimals = state.aiPlayer.capturedAnimals.count + simulatedAnimalGain
        if totalAnimals >= 5 { additionalScore += max(0, totalAnimals - 4 - max(0, state.aiPlayer.capturedAnimals.count - 4)) }

        return Double(currentScore + additionalScore)
    }

    // MARK: - 상대 위협도

    private func evaluateOpponentThreat(state: GameState) -> Double {
        let opponent = state.humanPlayer
        let opponentScore = scoreCalc.calculateBaseScore(for: opponent)

        var threat: Double = Double(opponentScore) / 7.0 // 기본 위협도

        // 상대 광이 많으면 위험
        if opponent.capturedBrights.count >= 2 { threat += 1.5 }
        if opponent.capturedBrights.count >= 3 { threat += 3.0 }

        // 상대 고도리 가까우면 위험
        if opponent.godoriCards.count >= 2 { threat += 2.0 }

        // 상대 손패가 많으면 변수가 많아 위험
        let opponentHandRatio = Double(opponent.hand.count) / 10.0
        threat += opponentHandRatio

        return threat
    }

    // MARK: - 유틸리티

    private func ribbonSetProgress(_ ribbonType: RibbonType, player: Player) -> (Int, Int) {
        switch ribbonType {
        case .redPoetry: return (player.redPoetryRibbons.count, 3)
        case .bluePlain: return (player.bluePlainRibbons.count, 3)
        case .redPlain:  return (player.redPlainRibbons.count, 3)
        case .none:      return (0, 3)
        }
    }
}
