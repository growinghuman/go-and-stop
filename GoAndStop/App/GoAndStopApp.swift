import SwiftUI

@main
struct GoAndStopApp: App {
    @State private var launchFinished = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainMenuView()
                    .preferredColorScheme(.dark)
                    .opacity(launchFinished ? 1 : 0)

                if showOnboarding && launchFinished {
                    OnboardingView(isPresented: $showOnboarding)
                        .transition(.opacity)
                }

                if !launchFinished {
                    LaunchScreenView(isFinished: $launchFinished)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: launchFinished)
            .animation(.easeInOut(duration: 0.3), value: showOnboarding)
            .onAppear {
                GameCenterManager.shared.authenticate()
            }
        }
    }
}
