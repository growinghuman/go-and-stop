import UIKit

enum AppColors {
    static let tableGreen = UIColor(red: 0.07, green: 0.27, blue: 0.17, alpha: 1)
    static let darkGreen = UIColor(red: 0.04, green: 0.18, blue: 0.10, alpha: 1)
    static let gold = UIColor(red: 1.0, green: 0.84, blue: 0, alpha: 1)
    static let cardRed = UIColor(red: 0.8, green: 0.1, blue: 0.15, alpha: 1)
    static let brightYellow = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1)
}

enum AppConstants {
    static let appName = "맞고"
    static let appSubtitle = "Go & Stop"
    static let version = "1.0.0"

    // 게임 기본값
    static let defaultMinScore = 7
    static let defaultAIDifficulty: AIDifficulty = .intermediate
    static let defaultGameSpeed: Double = 1.0

    // 레이아웃
    static let screenPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 4
}
