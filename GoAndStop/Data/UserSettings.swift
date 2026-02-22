import Foundation
import SwiftUI

/// 사용자 설정 관리
class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("masterVolume") var masterVolume: Double = 0.8
    @AppStorage("sfxVolume") var sfxVolume: Double = 1.0
    @AppStorage("bgmVolume") var bgmVolume: Double = 0.5
    @AppStorage("voiceEnabled") var voiceEnabled = true
    @AppStorage("hapticEnabled") var hapticEnabled = true
    @AppStorage("hapticIntensity") var hapticIntensity: Double = 1.0
    @AppStorage("gameSpeed") var gameSpeed: Double = 1.0
    @AppStorage("aiDifficulty") var aiDifficulty: String = AIDifficulty.intermediate.rawValue
    @AppStorage("minimumScore") var minimumScore: Int = 7
    @AppStorage("tableTheme") var tableTheme: String = "green"

    // 통계
    @AppStorage("totalGames") var totalGames: Int = 0
    @AppStorage("totalWins") var totalWins: Int = 0
    @AppStorage("totalLosses") var totalLosses: Int = 0
    @AppStorage("highestScore") var highestScore: Int = 0
    @AppStorage("maxGoStreak") var maxGoStreak: Int = 0
    @AppStorage("totalGodori") var totalGodori: Int = 0
    @AppStorage("totalBrightSets") var totalBrightSets: Int = 0

    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalWins) / Double(totalGames)
    }

    func recordGame(won: Bool, score: Int, goCount: Int, hadGodori: Bool, brightCount: Int) {
        totalGames += 1
        if won {
            totalWins += 1
        } else {
            totalLosses += 1
        }
        if score > highestScore {
            highestScore = score
        }
        if goCount > maxGoStreak {
            maxGoStreak = goCount
        }
        if hadGodori {
            totalGodori += 1
        }
        if brightCount >= 3 {
            totalBrightSets += 1
        }
    }

    func applyToManagers() {
        SoundManager.shared.masterVolume = Float(masterVolume)
        SoundManager.shared.sfxVolume = Float(sfxVolume)
        SoundManager.shared.bgmVolume = Float(bgmVolume)
        SoundManager.shared.voiceEnabled = voiceEnabled
        HapticManager.shared.isEnabled = hapticEnabled
        HapticManager.shared.intensity = Float(hapticIntensity)
        CardNode.animationSpeed = CGFloat(gameSpeed)
    }
}
