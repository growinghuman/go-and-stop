import SwiftUI
import SpriteKit

/// 메인 게임 컨테이너 뷰
struct GameContainerView: View {
    let difficulty: AIDifficulty

    @StateObject private var engine = MatchGoEngine()
    @State private var showGoStopDialog = false
    @State private var showResultView = false
    @State private var currentPhase: GamePhase = .notStarted
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // SpriteKit 게임 씬
            GameSpriteView(engine: engine, onPhaseChange: { phase in
                currentPhase = phase
                handlePhaseChange(phase)
            })
            .ignoresSafeArea()

            // UI 오버레이
            VStack {
                // 상단 바: AI 정보
                topBar
                Spacer()
                // 하단 바: 플레이어 점수 + 버튼
                bottomBar
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // 고/스톱 다이얼로그
            if showGoStopDialog {
                GoStopDialog(
                    score: engine.state.humanScore,
                    goCount: engine.state.humanPlayer.goCount,
                    onGo: {
                        showGoStopDialog = false
                        engine.playerCallGo()
                    },
                    onStop: {
                        showGoStopDialog = false
                        engine.playerCallStop()
                    }
                )
            }

            // 결과 화면
            if showResultView {
                GameResultView(
                    state: engine.state,
                    onPlayAgain: {
                        showResultView = false
                        startNewGame()
                    },
                    onQuit: {
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            setupAI()
            startNewGame()
        }
        .statusBarHidden(true)
    }

    // MARK: - Top Bar (AI Info)

    private var topBar: some View {
        HStack {
            // 뒤로가기
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.body.bold())
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            Spacer()

            // AI 정보
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 6) {
                    Text("AI")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(difficulty.displayName)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }

                HStack(spacing: 8) {
                    ScoreBadge(label: "점수", value: "\(engine.state.aiScore)", color: .red)
                    if engine.state.aiPlayer.goCount > 0 {
                        GoBadge(count: engine.state.aiPlayer.goCount)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Bottom Bar (Player Info)

    private var bottomBar: some View {
        VStack(spacing: 8) {
            // 획득 카드 요약
            CapturedCardsSummary(player: engine.state.humanPlayer)

            HStack {
                // 점수 표시
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        ScoreBadge(label: "점수", value: "\(engine.state.humanScore)", color: .blue)
                        if engine.state.humanPlayer.goCount > 0 {
                            GoBadge(count: engine.state.humanPlayer.goCount)
                        }
                    }
                }

                Spacer()

                // 턴 표시
                if currentPhase == .playerTurnSelectCard {
                    Text("패를 선택하세요")
                        .font(.caption)
                        .foregroundColor(.systemYellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(Capsule())
                } else if currentPhase == .aiTurn {
                    Text("AI 턴...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                // 남은 덱
                HStack(spacing: 4) {
                    Image(systemName: "square.stack.fill")
                        .font(.caption2)
                    Text("\(engine.state.deck.count)")
                        .font(.caption.monospacedDigit())
                }
                .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Actions

    private func setupAI() {
        switch difficulty {
        case .beginner:
            engine.aiPlayer = BeginnerAI()
        case .intermediate:
            engine.aiPlayer = IntermediateAI()
        case .expert:
            engine.aiPlayer = IntermediateAI() // TODO: ExpertAI
        }
    }

    private func startNewGame() {
        engine.startNewGame()
    }

    private func handlePhaseChange(_ phase: GamePhase) {
        switch phase {
        case .playerTurnGoStop:
            showGoStopDialog = true
        case .aiTurn:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                engine.executeAITurn()
            }
        case .aiTurnGoStop:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                engine.executeAIGoStopDecision()
            }
        case .roundEnd, .gameOver:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showResultView = true
            }
        case .nagari:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                engine.restartAfterNagari()
            }
        default:
            break
        }
    }
}

// MARK: - SpriteKit View Wrapper

struct GameSpriteView: UIViewRepresentable {
    let engine: MatchGoEngine
    let onPhaseChange: (GamePhase) -> Void

    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.preferredFramesPerSecond = 60
        skView.ignoresSiblingOrder = true

        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.configure(engine: engine)
        scene.onPhaseChange = onPhaseChange
        scene.onSoundEvent = { event in
            SoundManager.shared.play(event)
        }
        skView.presentScene(scene)

        // 배분 시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            scene.dealCards {
                // 배분 완료
            }
        }

        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {}
}

// MARK: - Go/Stop Dialog

struct GoStopDialog: View {
    let score: Int
    let goCount: Int
    let onGo: () -> Void
    let onStop: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {} // 배경 터치 방지

            VStack(spacing: 20) {
                Text("현재 \(score)점!")
                    .font(.title.bold())
                    .foregroundColor(.white)

                if goCount > 0 {
                    Text("\(goCount)고 진행 중")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }

                Text("고를 외치면 점수가 올라가지만\n상대가 먼저 스톱하면 잃습니다!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                HStack(spacing: 20) {
                    // 고 버튼
                    Button(action: onGo) {
                        VStack(spacing: 4) {
                            Text("고!")
                                .font(.title.bold())
                            Text(goCount >= 2 ? "점수 ×\(goCount)" : "+\(goCount + 1)점")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .frame(width: 120, height: 70)
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .red.opacity(0.4), radius: 6, y: 3)
                    }

                    // 스톱 버튼
                    Button(action: onStop) {
                        VStack(spacing: 4) {
                            Text("스톱!")
                                .font(.title.bold())
                            Text("\(score)점 확정")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .frame(width: 120, height: 70)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.4), radius: 6, y: 3)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .shadow(radius: 20)
            )
            .scaleEffect(appear ? 1 : 0.8)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}

// MARK: - Game Result View

struct GameResultView: View {
    let state: GameState
    let onPlayAgain: () -> Void
    let onQuit: () -> Void

    @State private var appear = false
    @State private var showScore = false

    var isWin: Bool { state.winner == .human }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // 결과 타이틀
                Text(isWin ? "승리!" : "패배")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(
                        isWin ?
                        LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.gray, .white], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: isWin ? .yellow.opacity(0.5) : .clear, radius: 10)

                // 점수
                if showScore {
                    VStack(spacing: 8) {
                        Text("최종 점수")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        Text("\(state.finalScore)점")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        // 배수 상세
                        if !state.scoreMultipliers.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(state.scoreMultipliers, id: \.self) { multiplier in
                                    Text(multiplier)
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // 점수 비교
                HStack(spacing: 30) {
                    VStack {
                        Text("나")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(state.humanScore)")
                            .font(.title2.bold())
                            .foregroundColor(.cyan)
                    }

                    Text("vs")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))

                    VStack {
                        Text("AI")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(state.aiScore)")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // 버튼
                VStack(spacing: 12) {
                    Button(action: onPlayAgain) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("다시 하기")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: onQuit) {
                        Text("나가기")
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                    .shadow(radius: 30)
            )
            .scaleEffect(appear ? 1 : 0.7)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appear = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showScore = true
            }
        }
    }
}

// MARK: - 점수 뱃지

struct ScoreBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color == .red ? .red : .cyan)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - 고 뱃지

struct GoBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)고")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.orange)
            )
    }
}

// MARK: - 획득 카드 요약

struct CapturedCardsSummary: View {
    @ObservedObject var player: Player

    var body: some View {
        HStack(spacing: 12) {
            CaptureGroup(emoji: "🌟", count: player.capturedBrights.count, label: "광")
            CaptureGroup(emoji: "🦌", count: player.capturedAnimals.count, label: "열끗")
            CaptureGroup(emoji: "🎀", count: player.capturedRibbons.count, label: "띠")
            CaptureGroup(emoji: "🍃", count: player.totalJunkCount, label: "피")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct CaptureGroup: View {
    let emoji: String
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Text(emoji)
                .font(.system(size: 12))
            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    GameContainerView(difficulty: .intermediate)
}
