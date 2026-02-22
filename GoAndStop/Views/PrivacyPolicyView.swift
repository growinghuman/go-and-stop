import SwiftUI

/// 개인정보 처리방침 뷰
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        policySection(
                            title: "개인정보 처리방침",
                            content: """
                            "맞고 Go & Stop" (이하 "앱")은 사용자의 개인정보를 소중히 여기며, \
                            관련 법규를 준수합니다. 본 방침은 앱이 어떤 정보를 수집하고 \
                            어떻게 사용하는지 설명합니다.
                            """
                        )

                        policySection(
                            title: "1. 수집하는 정보",
                            content: """
                            본 앱은 개인정보를 수집하지 않습니다.

                            - 이름, 이메일, 전화번호 등 개인 식별 정보를 수집하지 않습니다.
                            - 위치 정보를 수집하지 않습니다.
                            - 사진, 연락처 등 기기 데이터에 접근하지 않습니다.

                            게임 설정 및 통계 데이터는 기기 내부(UserDefaults)에만 저장되며 \
                            외부 서버로 전송되지 않습니다.
                            """
                        )

                        policySection(
                            title: "2. Game Center",
                            content: """
                            Apple Game Center 사용 시, Game Center 프로필 정보 \
                            (닉네임, 프로필 사진)가 Apple의 정책에 따라 처리됩니다.

                            리더보드 점수와 업적 달성 정보는 Apple Game Center를 통해 \
                            관리되며, 이는 Apple의 개인정보 처리방침을 따릅니다.
                            """
                        )

                        policySection(
                            title: "3. 데이터 저장",
                            content: """
                            본 앱에서 저장하는 데이터:

                            - 게임 설정 (음량, 난이도, 테마 등)
                            - 게임 전적 (승/패, 점수 기록)
                            - 게임 통계 (총 플레이 횟수, 최고 점수 등)

                            모든 데이터는 사용자의 기기에만 로컬로 저장되며, \
                            앱을 삭제하면 함께 삭제됩니다.
                            """
                        )
                    }

                    Group {
                        policySection(
                            title: "4. 제3자 공유",
                            content: """
                            본 앱은 어떠한 사용자 데이터도 제3자와 공유하지 않습니다.
                            """
                        )

                        policySection(
                            title: "5. 아동 개인정보",
                            content: """
                            본 앱은 만 13세 미만의 아동으로부터 고의로 개인정보를 \
                            수집하지 않습니다. 본 앱은 도박 요소가 없는 카드 게임이며, \
                            실제 금전 거래가 발생하지 않습니다.
                            """
                        )

                        policySection(
                            title: "6. 변경 사항",
                            content: """
                            본 개인정보 처리방침은 필요에 따라 업데이트될 수 있습니다. \
                            변경 시 앱 내 공지를 통해 안내합니다.
                            """
                        )

                        policySection(
                            title: "7. 문의",
                            content: """
                            개인정보 관련 문의사항이 있으시면 \
                            앱스토어 지원 페이지를 통해 연락해주세요.
                            """
                        )

                        Text("시행일: 2026년 2월 22일")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("개인정보 처리방침")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}
