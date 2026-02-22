import GameKit
import SwiftUI

/// Game Center 연동 관리자
class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var localPlayerName: String = ""
    @Published var localPlayerPhoto: UIImage?

    // 리더보드 ID
    enum LeaderboardID: String {
        case highScore = "com.goandstop.leaderboard.highscore"
        case totalWins = "com.goandstop.leaderboard.totalwins"
        case winStreak = "com.goandstop.leaderboard.winstreak"
    }

    // 업적 ID
    enum AchievementID: String {
        case firstWin = "com.goandstop.achievement.firstwin"
        case tenWins = "com.goandstop.achievement.tenwins"
        case fiftyWins = "com.goandstop.achievement.fiftywins"
        case hundredWins = "com.goandstop.achievement.hundredwins"
        case godoriMaster = "com.goandstop.achievement.godorimaster"
        case brightKing = "com.goandstop.achievement.brightking"
        case threeGo = "com.goandstop.achievement.threego"
        case perfectGame = "com.goandstop.achievement.perfectgame"
        case beatExpert = "com.goandstop.achievement.beatexpert"
        case hundredPoints = "com.goandstop.achievement.hundredpoints"
    }

    private override init() {
        super.init()
    }

    // MARK: - 인증

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let error = error {
                print("Game Center auth error: \(error.localizedDescription)")
                return
            }

            if let vc = viewController {
                // 로그인 UI 표시
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true)
                }
                return
            }

            if GKLocalPlayer.local.isAuthenticated {
                DispatchQueue.main.async {
                    self?.isAuthenticated = true
                    self?.localPlayerName = GKLocalPlayer.local.displayName
                }

                // 프로필 사진 로드
                GKLocalPlayer.local.loadPhoto(for: .small) { image, _ in
                    DispatchQueue.main.async {
                        self?.localPlayerPhoto = image
                    }
                }
            }
        }
    }

    // MARK: - 리더보드

    func submitScore(_ score: Int, to leaderboard: LeaderboardID) {
        guard isAuthenticated else { return }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboard.rawValue]
        ) { error in
            if let error = error {
                print("Score submit error: \(error.localizedDescription)")
            }
        }
    }

    func showLeaderboard(leaderboardID: LeaderboardID? = nil) {
        guard isAuthenticated else { return }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let gcVC = GKGameCenterViewController(state: .leaderboards)
        if let id = leaderboardID {
            gcVC.leaderboardIdentifier = id.rawValue
        }
        gcVC.gameCenterDelegate = self
        rootVC.present(gcVC, animated: true)
    }

    // MARK: - 업적

    func reportAchievement(_ achievement: AchievementID, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }

        let gcAchievement = GKAchievement(identifier: achievement.rawValue)
        gcAchievement.percentComplete = percentComplete
        gcAchievement.showsCompletionBanner = true

        GKAchievement.report([gcAchievement]) { error in
            if let error = error {
                print("Achievement report error: \(error.localizedDescription)")
            }
        }
    }

    func showAchievements() {
        guard isAuthenticated else { return }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = self
        rootVC.present(gcVC, animated: true)
    }

    // MARK: - 게임 결과 기반 업적/리더보드 처리

    func processGameResult(won: Bool, score: Int, goCount: Int, hadGodori: Bool,
                           brightCount: Int, difficulty: AIDifficulty) {
        guard isAuthenticated else { return }

        // 리더보드: 최고 점수
        submitScore(score, to: .highScore)

        // 리더보드: 총 승수
        if won {
            let totalWins = UserSettings.shared.totalWins
            submitScore(totalWins, to: .totalWins)
        }

        // 업적 체크
        if won {
            // 첫 승리
            if UserSettings.shared.totalWins == 1 {
                reportAchievement(.firstWin)
            }

            // 10승
            if UserSettings.shared.totalWins >= 10 {
                reportAchievement(.tenWins)
            }

            // 50승
            if UserSettings.shared.totalWins >= 50 {
                reportAchievement(.fiftyWins)
            }

            // 100승
            if UserSettings.shared.totalWins >= 100 {
                reportAchievement(.hundredWins)
            }

            // 고급 AI 격파
            if difficulty == .expert {
                reportAchievement(.beatExpert)
            }

            // 100점 이상
            if score >= 100 {
                reportAchievement(.hundredPoints)
            }

            // 퍼펙트 게임 (50점 이상)
            if score >= 50 {
                reportAchievement(.perfectGame)
            }
        }

        // 고도리 달성
        if hadGodori {
            reportAchievement(.godoriMaster)
        }

        // 3고 이상
        if goCount >= 3 {
            reportAchievement(.threeGo)
        }

        // 오광
        if brightCount >= 5 {
            reportAchievement(.brightKing)
        }
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
