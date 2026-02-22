import SwiftUI

@main
struct GoAndStopApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .preferredColorScheme(.dark)
        }
    }
}
