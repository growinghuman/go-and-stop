import SwiftUI

/// 첫 실행 시 온보딩 / 튜토리얼 화면
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var animateContent = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "🎴",
            title: "맞고에 오신 것을 환영합니다!",
            subtitle: "한국 전통 화투 카드 게임",
            description: "48장의 화투 카드로 즐기는\n전략적 카드 매칭 게임입니다.",
            color: Color(red: 1, green: 0.84, blue: 0)
        ),
        OnboardingPage(
            icon: "🌸",
            title: "카드 매칭",
            subtitle: "같은 월의 카드를 모으세요",
            description: "손패에서 카드를 내고, 바닥의 같은 월 카드와\n매칭하여 가져갑니다.\n덱에서 한 장 더 뒤집어 추가 매칭!",
            color: .pink
        ),
        OnboardingPage(
            icon: "⭐",
            title: "점수 & 족보",
            subtitle: "광, 띠, 열끗, 피를 모으세요",
            description: "광 3장 이상, 띠 3장 세트, 열끗 5장 이상,\n피 10장 이상으로 점수를 획득합니다.\n고도리, 홍단, 청단 등 특수 족보도!",
            color: .orange
        ),
        OnboardingPage(
            icon: "🔥",
            title: "고 & 스톱",
            subtitle: "전략적 판단이 핵심!",
            description: "기준 점수 달성 시 '고'로 더 높은 점수를 노리거나\n'스톱'으로 안전하게 확정하세요.\n고를 외칠수록 점수 배수가 올라갑니다!",
            color: .red
        ),
        OnboardingPage(
            icon: "🎮",
            title: "준비 완료!",
            subtitle: "지금 바로 시작하세요",
            description: "3단계 AI 난이도로\n초보부터 고수까지 즐길 수 있습니다.\n규칙서에서 상세 규칙을 확인하세요!",
            color: Color(red: 0.3, green: 0.8, blue: 0.4)
        )
    ]

    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.18, blue: 0.10),
                    Color(red: 0.07, green: 0.27, blue: 0.17)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 페이지 콘텐츠
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // 페이지 인디케이터
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ?
                                  pages[currentPage].color : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 10 : 6,
                                   height: index == currentPage ? 10 : 6)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)

                // 버튼
                if currentPage == pages.count - 1 {
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Text("시작하기!")
                            .font(.title3.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(pages[currentPage].color)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 40)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    HStack {
                        Button("건너뛰기") {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                        .foregroundColor(.white.opacity(0.5))

                        Spacer()

                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text("다음")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .frame(height: 48)
                            .background(pages[currentPage].color)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 30)
                }

                Spacer()
                    .frame(height: 50)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text(page.icon)
                .font(.system(size: 80))
                .shadow(radius: 10)

            Text(page.title)
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.headline)
                .foregroundColor(page.color)

            Text(page.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 30)

            Spacer()
            Spacer()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let color: Color
}
