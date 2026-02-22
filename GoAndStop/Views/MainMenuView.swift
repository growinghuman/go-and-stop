import SwiftUI

struct MainMenuView: View {
    @State private var showGame = false
    @State private var showSettings = false
    @State private var showRules = false
    @State private var showStats = false
    @State private var selectedDifficulty: AIDifficulty = .intermediate
    @State private var animateTitle = false
    @State private var animateCards = false
    @State private var animateButtons = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.18, blue: 0.10),
                        Color(red: 0.07, green: 0.27, blue: 0.17),
                        Color(red: 0.04, green: 0.20, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 배경 장식 - 떠다니는 화투 패턴
                FloatingCardsBackground()

                VStack(spacing: 0) {
                    Spacer()

                    // 타이틀
                    VStack(spacing: 8) {
                        Text("맞 고")
                            .font(.system(size: 64, weight: .black, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1, green: 0.84, blue: 0),
                                             Color(red: 1, green: 0.65, blue: 0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 3)
                            .scaleEffect(animateTitle ? 1.0 : 0.5)
                            .opacity(animateTitle ? 1.0 : 0)

                        Text("GO & STOP")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(8)
                            .opacity(animateTitle ? 1.0 : 0)

                        // 화투 카드 미니 아이콘
                        HStack(spacing: 12) {
                            ForEach(["🌸", "🐦", "🌕", "🍂", "☔"], id: \.self) { emoji in
                                Text(emoji)
                                    .font(.title)
                                    .scaleEffect(animateCards ? 1.0 : 0)
                            }
                        }
                        .padding(.top, 8)
                    }

                    Spacer()

                    // 난이도 선택
                    VStack(spacing: 12) {
                        Text("AI 난이도")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: 12) {
                            ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                                DifficultyButton(
                                    difficulty: difficulty,
                                    isSelected: selectedDifficulty == difficulty
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedDifficulty = difficulty
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 30)
                    .opacity(animateButtons ? 1.0 : 0)
                    .offset(y: animateButtons ? 0 : 20)

                    // 메인 버튼
                    VStack(spacing: 14) {
                        // 게임 시작 버튼
                        Button(action: { showGame = true }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.title3)
                                Text("게임 시작")
                                    .font(.title2.bold())
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1, green: 0.84, blue: 0),
                                             Color(red: 1, green: 0.7, blue: 0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color(red: 1, green: 0.84, blue: 0).opacity(0.4), radius: 8, y: 4)
                        }

                        HStack(spacing: 10) {
                            // 전적
                            Button(action: { showStats = true }) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                    Text("전적")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            // 규칙 설명
                            Button(action: { showRules = true }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                    Text("규칙")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            // 설정
                            Button(action: { showSettings = true }) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("설정")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        // Game Center 버튼
                        if GameCenterManager.shared.isAuthenticated {
                            HStack(spacing: 10) {
                                Button(action: {
                                    GameCenterManager.shared.showLeaderboard()
                                }) {
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                        Text("순위")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.yellow.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Color.yellow.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                Button(action: {
                                    GameCenterManager.shared.showAchievements()
                                }) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                        Text("업적")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.yellow.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Color.yellow.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateButtons ? 1.0 : 0)
                    .offset(y: animateButtons ? 0 : 30)

                    Spacer()
                        .frame(height: 50)
                }
            }
            .fullScreenCover(isPresented: $showGame) {
                GameContainerView(difficulty: selectedDifficulty)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showRules) {
                RuleBookView()
            }
            .sheet(isPresented: $showStats) {
                StatsView()
            }
            .onAppear {
                BGMGenerator.shared.playLobbyBGM(volume: 0.15)
                UserSettings.shared.applyToManagers()

                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    animateTitle = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                    animateCards = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                    animateButtons = true
                }
            }
            .onDisappear {
                BGMGenerator.shared.stopBGM()
            }
        }
    }
}

// MARK: - Difficulty Button

struct DifficultyButton: View {
    let difficulty: AIDifficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(difficultyIcon)
                    .font(.title2)
                Text(difficulty.displayName)
                    .font(.caption.bold())
            }
            .foregroundColor(isSelected ? .black : .white)
            .frame(width: 80, height: 65)
            .background(
                isSelected ?
                    AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 1, green: 0.84, blue: 0), Color(red: 1, green: 0.7, blue: 0)],
                        startPoint: .top, endPoint: .bottom
                    )) :
                    AnyShapeStyle(Color.white.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    var difficultyIcon: String {
        switch difficulty {
        case .beginner:     return "🌱"
        case .intermediate: return "🔥"
        case .expert:       return "👑"
        }
    }
}

// MARK: - Floating Cards Background

struct FloatingCardsBackground: View {
    @State private var animate = false

    let emojis = ["🎴", "🌸", "🍂", "🌕", "🐦", "🦋", "🦌"]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<12, id: \.self) { i in
                Text(emojis[i % emojis.count])
                    .font(.system(size: CGFloat.random(in: 16...28)))
                    .opacity(0.08)
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: animate ?
                            CGFloat.random(in: 0...geo.size.height) :
                            CGFloat.random(in: 0...geo.size.height) + 20
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

#Preview {
    MainMenuView()
}
