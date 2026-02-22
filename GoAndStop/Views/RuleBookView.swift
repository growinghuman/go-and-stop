import SwiftUI

struct RuleBookView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // 기본 규칙
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ruleSection(title: "게임 소개", icon: "🎴", content: """
                        맞고는 화투(花鬪) 48장으로 즐기는 한국 대표 카드 게임입니다.
                        2명이 서로 카드를 맞추어 점수를 내는 게임으로, 일정 점수 이상이 되면 '고(Go)' 또는 '스톱(Stop)'을 선택합니다.
                        """)

                        ruleSection(title: "게임 진행", icon: "🔄", content: """
                        1. 각 플레이어에게 10장씩, 바닥에 8장 배분
                        2. 자기 차례에 손패 1장을 바닥에 냄
                        3. 같은 월의 카드가 바닥에 있으면 매칭하여 가져감
                        4. 없으면 바닥에 놓음
                        5. 덱에서 1장을 뒤집어 같은 과정 반복
                        6. 최소 점수 도달 시 고/스톱 선택
                        """)

                        ruleSection(title: "카드 종류 (48장)", icon: "🃏", content: """
                        🌟 광 (5장) - 가장 높은 가치
                        🦌 열끗/동물 (9장) - 동물 그림
                        🎀 띠/리본 (10장) - 띠 그림
                        🍃 피 (24장) - 기본 카드
                        """)
                    }
                    .padding()
                }
                .tag(0)

                // 점수 규칙
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ruleSection(title: "광 점수", icon: "🌟", content: """
                        • 오광 (5장 모두): 15점
                        • 사광 (비광 제외 4장): 4점
                        • 비사광 (비광 포함 4장): 4점
                        • 삼광 (비광 제외 3장): 3점
                        • 비삼광 (비광 포함 3장): 2점
                        """)

                        ruleSection(title: "띠 점수", icon: "🎀", content: """
                        • 홍단 (1,2,3월 빨간 띠): 3점
                        • 청단 (6,9,10월 파란 띠): 3점
                        • 초단 (4,5,7월 풀색 띠): 3점
                        • 띠 5장 이상: 1점 (추가 1장당 +1점)
                        """)

                        ruleSection(title: "열끗 점수", icon: "🦌", content: """
                        • 고도리 (2,4,8월 새): 5점
                        • 열끗 5장 이상: 1점 (추가 1장당 +1점)
                        """)

                        ruleSection(title: "피 점수", icon: "🍃", content: """
                        • 피 10장 이상: 1점 (추가 1장당 +1점)
                        • 쌍피는 2장으로 계산
                        """)
                    }
                    .padding()
                }
                .tag(1)

                // 특수 규칙
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ruleSection(title: "고/스톱", icon: "🔥", content: """
                        최소 점수(보통 7점) 이상이면 선택 가능:
                        • 고(Go): 게임 계속 - 점수 추가 기회
                          - 1고: +1점, 2고: +2점, 3고: 점수 ×2
                        • 스톱(Stop): 게임 종료 - 현재 점수 확정
                        ⚠️ 고를 외치면 상대가 먼저 이길 수 있음!
                        """)

                        ruleSection(title: "뻑", icon: "❌", content: """
                        바닥에 같은 월 카드가 2장 있을 때, 덱에서 뒤집은 카드도 같은 월이면 '뻑'!
                        3장 모두 바닥에 놓이며, 다음에 4장째가 나오면 한번에 가져감.
                        """)

                        ruleSection(title: "쪽", icon: "✨", content: """
                        손에서 낸 카드가 매칭 안 되어 바닥에 놓였는데, 덱에서 뒤집은 카드가 같은 월이면 '쪽'!
                        두 카드를 모두 가져갑니다.
                        """)

                        ruleSection(title: "쓸", icon: "🧹", content: """
                        카드를 먹어서 바닥 카드가 0장이 되면 '쓸'!
                        상대 피 1장을 가져옵니다.
                        """)

                        ruleSection(title: "폭탄", icon: "💣", content: """
                        같은 월 3장이 손에 있고 바닥에 1장이 있으면 '폭탄'!
                        4장을 한번에 먹고, 상대 피 1장을 빼앗습니다.
                        승리 시 점수 ×2!
                        """)

                        ruleSection(title: "벌칙 (박)", icon: "⚡", content: """
                        • 광박: 상대 광 0장 → +2점
                        • 피박: 상대 피 7장 이하 → 점수 ×2
                        • 멍박: 상대 열끗 0장 → 점수 ×2
                        """)

                        ruleSection(title: "나가리", icon: "🔁", content: """
                        양쪽 손패 모두 소진 시 아무도 스톱 못하면 '나가리'(무승부).
                        다음 판은 점수가 2배로 적용됩니다.
                        """)
                    }
                    .padding()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .navigationTitle("게임 규칙")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 16) {
                        TabButton(title: "기본", index: 0, selected: $selectedTab)
                        TabButton(title: "점수", index: 1, selected: $selectedTab)
                        TabButton(title: "특수", index: 2, selected: $selectedTab)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func ruleSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }

            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TabButton: View {
    let title: String
    let index: Int
    @Binding var selected: Int

    var body: some View {
        Button(action: {
            withAnimation { selected = index }
        }) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(selected == index ? .accentColor : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selected == index ? Color.accentColor.opacity(0.1) : Color.clear)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    RuleBookView()
}
