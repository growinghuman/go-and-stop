import SwiftUI

struct StatsView: View {
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var recordStore = GameRecordStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 종합 통계 카드
                    overallStatsCard

                    // 승률 차트
                    winRateCard

                    // 기록 달성
                    achievementsCard

                    // 최근 전적
                    recentGamesCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("전적")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    // MARK: - 종합 통계

    private var overallStatsCard: some View {
        VStack(spacing: 16) {
            Text("종합 통계")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                StatItem(value: "\(settings.totalGames)", label: "총 게임", color: .blue)
                Divider().frame(height: 40)
                StatItem(value: "\(settings.totalWins)", label: "승리", color: .green)
                Divider().frame(height: 40)
                StatItem(value: "\(settings.totalLosses)", label: "패배", color: .red)
                Divider().frame(height: 40)
                StatItem(value: "\(Int(settings.winRate * 100))%", label: "승률", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 승률 시각화

    private var winRateCard: some View {
        VStack(spacing: 12) {
            Text("승률")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if settings.totalGames > 0 {
                // 원형 진행 표시
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: settings.winRate)
                        .stroke(
                            LinearGradient(colors: [.green, .cyan], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(settings.winRate * 100))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("\(settings.totalWins)승 \(settings.totalLosses)패")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 140, height: 140)
                .padding(.vertical, 8)

                // 바 형태
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        if settings.totalWins > 0 {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geo.size.width * settings.winRate)
                        }
                        if settings.totalLosses > 0 {
                            Rectangle()
                                .fill(Color.red)
                        }
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 8)
            } else {
                Text("아직 게임 기록이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 기록 달성

    private var achievementsCard: some View {
        VStack(spacing: 12) {
            Text("기록")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AchievementItem(icon: "🏆", title: "최고 점수", value: "\(settings.highestScore)점")
                AchievementItem(icon: "🔥", title: "최대 연속 고", value: "\(settings.maxGoStreak)고")
                AchievementItem(icon: "🐦", title: "고도리 달성", value: "\(settings.totalGodori)회")
                AchievementItem(icon: "🌟", title: "삼광 이상", value: "\(settings.totalBrightSets)회")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 최근 전적

    private var recentGamesCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("최근 게임")
                    .font(.headline)
                Spacer()
                Text("\(recordStore.records.count)게임")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if recordStore.records.isEmpty {
                Text("게임을 플레이하면 여기에 기록됩니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(recordStore.records.prefix(10)) { record in
                    GameRecordRow(record: record)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 통계 아이템

struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 업적 아이템

struct AchievementItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 게임 기록 행

struct GameRecordRow: View {
    let record: GameRecord

    var body: some View {
        HStack(spacing: 12) {
            // 승패 아이콘
            Circle()
                .fill(record.won ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(record.won ? "승리" : "패배")
                .font(.subheadline.bold())
                .foregroundColor(record.won ? .green : .red)
                .frame(width: 36)

            // 점수
            Text("\(record.score)점")
                .font(.subheadline.monospacedDigit())

            // 배수 표시
            if !record.multipliers.isEmpty {
                Text(record.multipliers.first ?? "")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .lineLimit(1)
            }

            Spacer()

            // 날짜
            Text(record.date.formatted(.dateTime.month().day().hour().minute()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StatsView()
}
