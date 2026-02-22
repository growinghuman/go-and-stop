import SwiftUI

struct SettingsView: View {
    @AppStorage("masterVolume") private var masterVolume: Double = 0.8
    @AppStorage("sfxVolume") private var sfxVolume: Double = 1.0
    @AppStorage("bgmVolume") private var bgmVolume: Double = 0.5
    @AppStorage("voiceEnabled") private var voiceEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("hapticIntensity") private var hapticIntensity: Double = 1.0
    @AppStorage("gameSpeed") private var gameSpeed: Double = 1.0
    @AppStorage("minimumScore") private var minimumScore = 7
    @AppStorage("tableTheme") private var tableTheme = "green"

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // 사운드 설정
                Section {
                    VolumeSlider(label: "마스터 볼륨", value: $masterVolume, icon: "speaker.wave.3.fill")
                    VolumeSlider(label: "효과음", value: $sfxVolume, icon: "waveform")
                    VolumeSlider(label: "배경음악", value: $bgmVolume, icon: "music.note")
                    Toggle(isOn: $voiceEnabled) {
                        Label("음성 효과", systemImage: "mic.fill")
                    }
                } header: {
                    Text("사운드")
                }

                // 진동 설정
                Section {
                    Toggle(isOn: $hapticEnabled) {
                        Label("진동 피드백", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    if hapticEnabled {
                        VolumeSlider(label: "진동 강도", value: $hapticIntensity, icon: "waveform.path")
                    }
                } header: {
                    Text("햅틱")
                }

                // 게임 설정
                Section {
                    // 게임 속도
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("게임 속도", systemImage: "gauge.with.dots.needle.33percent")
                            Spacer()
                            Text(speedLabel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Picker("", selection: $gameSpeed) {
                            Text("느림").tag(0.7)
                            Text("보통").tag(1.0)
                            Text("빠름").tag(1.5)
                            Text("매우 빠름").tag(2.0)
                        }
                        .pickerStyle(.segmented)
                    }

                    // 스톱 최소 점수
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("스톱 최소 점수", systemImage: "target")
                            Spacer()
                            Text("\(minimumScore)점")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Picker("", selection: $minimumScore) {
                            Text("3점").tag(3)
                            Text("5점").tag(5)
                            Text("7점").tag(7)
                        }
                        .pickerStyle(.segmented)
                    }
                } header: {
                    Text("게임")
                }

                // 테마 설정
                Section {
                    Picker("바닥판 테마", selection: $tableTheme) {
                        Text("초록 매트").tag("green")
                        Text("나무결").tag("wood")
                        Text("진한 초록").tag("darkgreen")
                        Text("네이비").tag("navy")
                    }
                } header: {
                    Text("테마")
                }

                // 정보
                Section {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text(AppConstants.version)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("정보")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }

    private var speedLabel: String {
        switch gameSpeed {
        case 0.7: return "느림"
        case 1.0: return "보통"
        case 1.5: return "빠름"
        case 2.0: return "매우 빠름"
        default: return "보통"
        }
    }
}

// MARK: - Volume Slider

struct VolumeSlider: View {
    let label: String
    @Binding var value: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $value, in: 0...1, step: 0.05)
                .tint(.accentColor)
        }
    }
}

#Preview {
    SettingsView()
}
