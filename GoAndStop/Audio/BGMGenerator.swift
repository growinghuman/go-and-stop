import AVFoundation

/// 프로그래매틱 BGM 생성기 - 국악풍 펜타토닉 기반
class BGMGenerator {
    static let shared = BGMGenerator()

    private var bgmPlayer: AVAudioPlayer?
    private var isPlaying = false

    // 국악 펜타토닉 스케일 (궁상각치우)
    private let pentatonicScale: [Double] = [
        261.63, // 도 (궁)
        293.66, // 레 (상)
        329.63, // 미 (각)
        392.00, // 솔 (치)
        440.00, // 라 (우)
        523.25, // 높은 도
        587.33, // 높은 레
        659.25, // 높은 미
    ]

    // 저음부 (반주)
    private let bassNotes: [Double] = [
        130.81, // 낮은 도
        146.83, // 낮은 레
        164.81, // 낮은 미
        196.00, // 낮은 솔
        220.00, // 낮은 라
    ]

    private init() {}

    // MARK: - 로비 BGM 생성

    func generateLobbyBGM() -> Data? {
        let sampleRate: Double = 44100
        let duration: Double = 16.0 // 16초 루프
        let totalSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: totalSamples)

        let bpm: Double = 72 // 느긋한 템포
        let beatDuration = 60.0 / bpm
        let totalBeats = Int(duration / beatDuration)

        // 멜로디 패턴 (궁상각치우 기반)
        let melodyPattern: [Int] = [0, 2, 4, 3, 2, 0, 1, 3, 4, 5, 4, 2, 3, 1, 0, -1]
        let bassPattern: [Int] = [0, 0, 3, 3, 2, 2, 4, 0]

        for beat in 0..<totalBeats {
            let beatStart = Int(Double(beat) * beatDuration * sampleRate)

            // 멜로디
            let melodyIdx = melodyPattern[beat % melodyPattern.count]
            if melodyIdx >= 0 && melodyIdx < pentatonicScale.count {
                let freq = pentatonicScale[melodyIdx]
                addNote(to: &samples, startSample: beatStart, sampleRate: sampleRate,
                        frequency: freq, duration: beatDuration * 0.85, amplitude: 0.15,
                        waveType: .sine, envelope: .melodic)
            }

            // 베이스 (2비트마다)
            if beat % 2 == 0 {
                let bassIdx = bassPattern[(beat / 2) % bassPattern.count]
                let bassFreq = bassNotes[bassIdx]
                addNote(to: &samples, startSample: beatStart, sampleRate: sampleRate,
                        frequency: bassFreq, duration: beatDuration * 1.8, amplitude: 0.08,
                        waveType: .triangle, envelope: .pad)
            }

            // 가야금 풍 아르페지오 (4비트마다)
            if beat % 4 == 0 {
                let arpNotes = [0, 2, 4, 5]
                for (i, noteIdx) in arpNotes.enumerated() {
                    if noteIdx < pentatonicScale.count {
                        let arpStart = beatStart + Int(Double(i) * beatDuration * 0.2 * sampleRate)
                        let arpFreq = pentatonicScale[noteIdx]
                        addNote(to: &samples, startSample: arpStart, sampleRate: sampleRate,
                                frequency: arpFreq, duration: beatDuration * 0.5, amplitude: 0.06,
                                waveType: .pluck, envelope: .plucked)
                    }
                }
            }
        }

        // 페이드 인/아웃
        applyFade(samples: &samples, sampleRate: sampleRate, fadeInDuration: 1.0, fadeOutDuration: 2.0)

        return samplesToWAV(samples: samples, sampleRate: sampleRate)
    }

    // MARK: - 게임 중 BGM 생성

    func generateGameBGM() -> Data? {
        let sampleRate: Double = 44100
        let duration: Double = 12.0
        let totalSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: totalSamples)

        let bpm: Double = 100 // 좀 더 빠른 템포
        let beatDuration = 60.0 / bpm
        let totalBeats = Int(duration / beatDuration)

        // 긴장감 있는 패턴
        let melodyPattern: [Int] = [4, 3, 2, 0, 2, 4, 5, 4, 3, 2, 0, 1, 0, 2, 3, 4]
        let percPattern: [Bool] = [true, false, true, false, true, false, false, true]

        for beat in 0..<totalBeats {
            let beatStart = Int(Double(beat) * beatDuration * sampleRate)

            // 리듬감 있는 멜로디
            let melodyIdx = melodyPattern[beat % melodyPattern.count]
            if melodyIdx < pentatonicScale.count {
                let freq = pentatonicScale[melodyIdx]
                addNote(to: &samples, startSample: beatStart, sampleRate: sampleRate,
                        frequency: freq, duration: beatDuration * 0.6, amplitude: 0.12,
                        waveType: .sine, envelope: .staccato)
            }

            // 퍼커션 (장구풍)
            if percPattern[beat % percPattern.count] {
                addPercussion(to: &samples, startSample: beatStart, sampleRate: sampleRate,
                             amplitude: 0.08)
            }

            // 드론 베이스
            let bassIdx = (beat / 4) % bassNotes.count
            if beat % 4 == 0 {
                addNote(to: &samples, startSample: beatStart, sampleRate: sampleRate,
                        frequency: bassNotes[bassIdx], duration: beatDuration * 3.5, amplitude: 0.06,
                        waveType: .triangle, envelope: .pad)
            }
        }

        applyFade(samples: &samples, sampleRate: sampleRate, fadeInDuration: 0.5, fadeOutDuration: 1.5)

        return samplesToWAV(samples: samples, sampleRate: sampleRate)
    }

    // MARK: - 노트 생성

    private enum WaveType { case sine, triangle, pluck }
    private enum EnvelopeType { case melodic, staccato, pad, plucked }

    private func addNote(to samples: inout [Float], startSample: Int, sampleRate: Double,
                          frequency: Double, duration: Double, amplitude: Float,
                          waveType: WaveType, envelope: EnvelopeType) {
        let numSamples = Int(sampleRate * duration)

        for i in 0..<numSamples {
            let sampleIdx = startSample + i
            guard sampleIdx < samples.count else { break }

            let t = Double(i) / sampleRate
            let normalizedT = t / duration

            // 파형
            let phase = 2.0 * Double.pi * frequency * t
            var sample: Double
            switch waveType {
            case .sine:
                sample = sin(phase) + 0.3 * sin(phase * 2) + 0.1 * sin(phase * 3) // 배음 추가
            case .triangle:
                sample = 2.0 * abs(2.0 * (t * frequency - floor(t * frequency + 0.5))) - 1.0
            case .pluck:
                // 가야금풍: 높은 배음이 빨리 감쇠
                sample = sin(phase) * exp(-t * 3)
                    + 0.5 * sin(phase * 2) * exp(-t * 6)
                    + 0.3 * sin(phase * 3) * exp(-t * 9)
            }

            // 엔벨로프
            let env: Double
            switch envelope {
            case .melodic:
                if normalizedT < 0.05 { env = normalizedT / 0.05 }
                else if normalizedT < 0.2 { env = 1.0 - (normalizedT - 0.05) / 0.15 * 0.3 }
                else if normalizedT < 0.8 { env = 0.7 }
                else { env = 0.7 * (1.0 - (normalizedT - 0.8) / 0.2) }

            case .staccato:
                if normalizedT < 0.02 { env = normalizedT / 0.02 }
                else if normalizedT < 0.1 { env = 1.0 - (normalizedT - 0.02) / 0.08 * 0.5 }
                else { env = 0.5 * exp(-3.0 * (normalizedT - 0.1)) }

            case .pad:
                if normalizedT < 0.1 { env = normalizedT / 0.1 }
                else if normalizedT < 0.7 { env = 1.0 }
                else { env = 1.0 - (normalizedT - 0.7) / 0.3 }

            case .plucked:
                env = exp(-normalizedT * 5.0)
            }

            // 비브라토 (멜로디 음에만)
            var vibrato: Double = 1.0
            if envelope == .melodic && normalizedT > 0.3 {
                vibrato = 1.0 + 0.003 * sin(2.0 * Double.pi * 5.0 * t) // 5Hz 비브라토
            }

            samples[sampleIdx] += Float(sample * env * vibrato) * amplitude
        }
    }

    // MARK: - 퍼커션

    private func addPercussion(to samples: inout [Float], startSample: Int, sampleRate: Double,
                                amplitude: Float) {
        let duration = 0.08
        let numSamples = Int(sampleRate * duration)

        for i in 0..<numSamples {
            let sampleIdx = startSample + i
            guard sampleIdx < samples.count else { break }

            let t = Double(i) / sampleRate
            let normalizedT = t / duration

            // 장구 소리: 저주파 노이즈 + 톤
            let noise = Float.random(in: -1...1) * 0.5
            let tone = Float(sin(2.0 * Double.pi * 120 * t)) * 0.5
            let env = Float(exp(-normalizedT * 15.0))

            samples[sampleIdx] += (noise + tone) * env * amplitude
        }
    }

    // MARK: - 페이드

    private func applyFade(samples: inout [Float], sampleRate: Double,
                            fadeInDuration: Double, fadeOutDuration: Double) {
        let fadeInSamples = Int(sampleRate * fadeInDuration)
        let fadeOutSamples = Int(sampleRate * fadeOutDuration)

        for i in 0..<min(fadeInSamples, samples.count) {
            samples[i] *= Float(i) / Float(fadeInSamples)
        }

        let fadeOutStart = max(0, samples.count - fadeOutSamples)
        for i in fadeOutStart..<samples.count {
            let progress = Float(samples.count - i) / Float(fadeOutSamples)
            samples[i] *= progress
        }
    }

    // MARK: - WAV 변환

    private func samplesToWAV(samples: [Float], sampleRate: Double) -> Data {
        var data = Data()
        let dataSize = samples.count * 2
        let fileSize = 36 + dataSize

        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let intSample = Int16(clamped * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
        }

        return data
    }

    // MARK: - 재생 제어

    func playLobbyBGM(volume: Float = 0.3) {
        guard let data = generateLobbyBGM() else { return }
        playBGM(data: data, volume: volume)
    }

    func playGameBGM(volume: Float = 0.2) {
        guard let data = generateGameBGM() else { return }
        playBGM(data: data, volume: volume)
    }

    private func playBGM(data: Data, volume: Float) {
        do {
            bgmPlayer = try AVAudioPlayer(data: data)
            bgmPlayer?.volume = volume
            bgmPlayer?.numberOfLoops = -1 // 무한 반복
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
            isPlaying = true
        } catch {
            print("BGM playback error: \(error)")
        }
    }

    func stopBGM(fadeOut: Bool = true) {
        if fadeOut {
            let originalVolume = bgmPlayer?.volume ?? 0
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
                guard let player = self?.bgmPlayer else { timer.invalidate(); return }
                if player.volume > 0.01 {
                    player.volume -= originalVolume * 0.05
                } else {
                    player.stop()
                    self?.isPlaying = false
                    timer.invalidate()
                }
            }
        } else {
            bgmPlayer?.stop()
            isPlaying = false
        }
    }

    func setVolume(_ volume: Float) {
        bgmPlayer?.volume = volume
    }
}
