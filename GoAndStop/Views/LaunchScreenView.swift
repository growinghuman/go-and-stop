import SwiftUI

/// 커스텀 런치 스크린 (스플래시 화면)
struct LaunchScreenView: View {
    @State private var animateTitle = false
    @State private var animateGlow = false
    @State private var animateCards = false
    @State private var showLoading = false
    @Binding var isFinished: Bool

    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.18, blue: 0.10),
                    Color(red: 0.07, green: 0.27, blue: 0.17),
                    Color(red: 0.04, green: 0.20, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 배경 빛 효과
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.yellow.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(animateGlow ? 1.2 : 0.8)
                .opacity(animateGlow ? 1 : 0)

            VStack(spacing: 24) {
                Spacer()

                // 화투 카드 아이콘 3장
                HStack(spacing: -20) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.75, green: 0.1, blue: 0.15),
                                             Color(red: 0.6, green: 0.08, blue: 0.1)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 50, height: 72)
                            .overlay(
                                Text("花")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color(red: 1, green: 0.84, blue: 0).opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(red: 1, green: 0.84, blue: 0).opacity(0.3), lineWidth: 1)
                            )
                            .rotationEffect(.degrees(Double(i - 1) * 12))
                            .offset(y: i == 1 ? -8 : 0)
                            .scaleEffect(animateCards ? 1 : 0.3)
                            .opacity(animateCards ? 1 : 0)
                    }
                }
                .shadow(color: .black.opacity(0.5), radius: 10, y: 5)

                // 타이틀
                VStack(spacing: 8) {
                    Text("맞 고")
                        .font(.system(size: 56, weight: .black, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.84, blue: 0),
                                         Color(red: 1, green: 0.65, blue: 0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 3)
                        .scaleEffect(animateTitle ? 1.0 : 0.6)
                        .opacity(animateTitle ? 1.0 : 0)

                    Text("GO & STOP")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(6)
                        .opacity(animateTitle ? 1.0 : 0)
                }

                Spacer()

                // 로딩 표시
                if showLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white.opacity(0.5))
                            .scaleEffect(0.8)

                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .transition(.opacity)
                }

                Text("v\(AppConstants.version)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.2))

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            // 애니메이션 시퀀스
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                animateCards = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                animateTitle = true
            }
            withAnimation(.easeInOut(duration: 1.5).delay(0.2).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.8)) {
                showLoading = true
            }

            // 텍스쳐 프리로딩
            TextureCache.shared.preloadAllCardTextures {
                // 최소 2초 표시 후 전환
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isFinished = true
                    }
                }
            }
        }
    }
}
