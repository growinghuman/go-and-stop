import Foundation

/// 맞고 점수 계산 엔진
struct ScoreCalculator {
    let rules: GameRules

    init(rules: GameRules = .standard) {
        self.rules = rules
    }

    // MARK: - 전체 점수 계산

    /// 플레이어의 현재 기본 점수 계산 (배수 적용 전)
    func calculateBaseScore(for player: Player) -> Int {
        var score = 0
        score += brightScore(for: player)
        score += godoriScore(for: player)
        score += ribbonScore(for: player)
        score += animalScore(for: player)
        score += junkScore(for: player)
        return score
    }

    /// 최종 점수 계산 (배수 포함)
    func calculateFinalScore(winner: Player, loser: Player, nagariMultiplier: Int = 1) -> (score: Int, multipliers: [String]) {
        var score = calculateBaseScore(for: winner)
        var multipliers: [String] = []

        // 고 보너스
        if winner.goCount > 0 {
            if winner.goCount <= 2 {
                score += winner.goCount
                multipliers.append("\(winner.goCount)고 (+\(winner.goCount)점)")
            } else {
                let goMultiplier = winner.goCount - 1
                score *= goMultiplier
                multipliers.append("\(winner.goCount)고 (×\(goMultiplier))")
            }
        }

        // 광박: 상대가 광 0장
        if loser.capturedBrights.isEmpty && winner.capturedBrights.count > 0 {
            if rules.brightPenaltyIsMultiplier {
                score *= 2
                multipliers.append("광박 (×2)")
            } else {
                score += 2
                multipliers.append("광박 (+2)")
            }
        }

        // 피박: 상대 피가 threshold 이하
        if loser.totalJunkCount <= rules.junkPenaltyThreshold {
            score *= 2
            multipliers.append("피박 (×2)")
        }

        // 멍박: 상대 열끗 0장
        if rules.enableAnimalPenalty && loser.capturedAnimals.isEmpty && winner.capturedAnimals.count > 0 {
            score *= 2
            multipliers.append("멍박 (×2)")
        }

        // 흔듦 배수
        if winner.shakeCount > 0 {
            for _ in 0..<winner.shakeCount {
                score *= 2
            }
            multipliers.append("흔듦 \(winner.shakeCount)회 (×\(Int(pow(2.0, Double(winner.shakeCount)))))")
        }

        // 폭탄 배수
        if winner.bombCount > 0 {
            for _ in 0..<winner.bombCount {
                score *= 2
            }
            multipliers.append("폭탄 \(winner.bombCount)회 (×\(Int(pow(2.0, Double(winner.bombCount)))))")
        }

        // 나가리 배수
        if nagariMultiplier > 1 {
            score *= nagariMultiplier
            multipliers.append("나가리 (×\(nagariMultiplier))")
        }

        return (score, multipliers)
    }

    // MARK: - 광 점수

    func brightScore(for player: Player) -> Int {
        let brights = player.capturedBrights
        let count = brights.count
        let hasRainBright = brights.contains { $0.isRainBright }

        switch count {
        case 5:
            return rules.fiveBrightScore
        case 4:
            return 4 // 사광 (비광 포함 여부 무관하게 4점)
        case 3:
            return hasRainBright ? rules.rainThreeBrightScore : 3
        default:
            return 0
        }
    }

    // MARK: - 고도리 점수

    func godoriScore(for player: Player) -> Int {
        return player.hasGodori ? rules.godoriScore : 0
    }

    // MARK: - 띠 점수

    func ribbonScore(for player: Player) -> Int {
        var score = 0

        // 홍단 (1, 2, 3월 홍단)
        if player.redPoetryRibbons.count >= 3 {
            score += 3
        }

        // 청단 (6, 9, 10월 청단)
        if player.bluePlainRibbons.count >= 3 {
            score += 3
        }

        // 초단 (4, 5, 7월 초단)
        if player.redPlainRibbons.count >= 3 {
            score += 3
        }

        // 띠 5장 이상 보너스
        let totalRibbons = player.capturedRibbons.count
        if totalRibbons >= 5 {
            score += (totalRibbons - 4)
        }

        return score
    }

    // MARK: - 열끗 점수

    func animalScore(for player: Player) -> Int {
        let count = player.capturedAnimals.count
        if count >= 5 {
            return count - 4
        }
        return 0
    }

    // MARK: - 피 점수

    func junkScore(for player: Player) -> Int {
        let count = player.totalJunkCount
        if count >= 10 {
            return count - 9
        }
        return 0
    }

    // MARK: - 스톱 가능 여부

    func canStop(player: Player) -> Bool {
        return calculateBaseScore(for: player) >= rules.minimumScoreToStop
    }

    /// 고/스톱 선택 가능한지 (최소 점수 이상)
    func canCallGoOrStop(player: Player) -> Bool {
        return calculateBaseScore(for: player) >= rules.minimumScoreToStop
    }

    // MARK: - 점수 상세 내역

    struct ScoreBreakdown {
        var brightScore: Int = 0
        var brightDetail: String = ""
        var godoriScore: Int = 0
        var ribbonScore: Int = 0
        var ribbonDetail: String = ""
        var animalScore: Int = 0
        var junkScore: Int = 0
        var totalBase: Int = 0
    }

    func getBreakdown(for player: Player) -> ScoreBreakdown {
        var bd = ScoreBreakdown()
        bd.brightScore = brightScore(for: player)
        bd.godoriScore = godoriScore(for: player)
        bd.ribbonScore = ribbonScore(for: player)
        bd.animalScore = animalScore(for: player)
        bd.junkScore = junkScore(for: player)
        bd.totalBase = bd.brightScore + bd.godoriScore + bd.ribbonScore + bd.animalScore + bd.junkScore

        // 광 상세
        let bc = player.capturedBrights.count
        if bc == 5 { bd.brightDetail = "오광" }
        else if bc == 4 { bd.brightDetail = "사광" }
        else if bc == 3 {
            bd.brightDetail = player.capturedBrights.contains(where: { $0.isRainBright }) ? "비삼광" : "삼광"
        }

        // 띠 상세
        var ribbonDetails: [String] = []
        if player.redPoetryRibbons.count >= 3 { ribbonDetails.append("홍단") }
        if player.bluePlainRibbons.count >= 3 { ribbonDetails.append("청단") }
        if player.redPlainRibbons.count >= 3 { ribbonDetails.append("초단") }
        if player.capturedRibbons.count >= 5 { ribbonDetails.append("띠 \(player.capturedRibbons.count)장") }
        bd.ribbonDetail = ribbonDetails.joined(separator: ", ")

        return bd
    }
}
