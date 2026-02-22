import AVFoundation
import Combine

/// 사운드 효과 관리자
class SoundManager {
    static let shared = SoundManager()

    private var audioEngine: AVAudioEngine
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    private var bgmPlayer: AVAudioPlayer?

    // 볼륨 설정
    var masterVolume: Float = 0.8 {
        didSet { updateVolumes() }
    }
    var sfxVolume: Float = 1.0 {
        didSet { updateVolumes() }
    }
    var bgmVolume: Float = 0.5 {
        didSet { updateVolumes() }
    }
    var voiceEnabled: Bool = true

    private init() {
        audioEngine = AVAudioEngine()
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    // MARK: - 사운드 이벤트 재생

    func play(_ event: SoundEvent) {
        let effectiveVolume = masterVolume * sfxVolume

        switch event {
        case .cardDeal:
            playSystemSound(.cardDeal, volume: effectiveVolume * 0.6)
        case .cardPlay:
            playSystemSound(.cardPlay, volume: effectiveVolume)
        case .cardMatch:
            playSystemSound(.cardMatch, volume: effectiveVolume)
        case .cardFlip:
            playSystemSound(.cardFlip, volume: effectiveVolume * 0.8)
        case .goCall:
            playSystemSound(.goCall, volume: effectiveVolume)
            HapticManager.shared.playGoHaptic()
        case .stopCall:
            playSystemSound(.stopCall, volume: effectiveVolume)
            HapticManager.shared.playStopHaptic()
        case .bomb:
            playSystemSound(.bomb, volume: effectiveVolume)
            HapticManager.shared.playBombHaptic()
        case .shake:
            playSystemSound(.shake, volume: effectiveVolume)
            HapticManager.shared.playShakeHaptic()
        case .winCheer:
            playSystemSound(.winCheer, volume: effectiveVolume)
            HapticManager.shared.playWinHaptic()
        case .winBig:
            playSystemSound(.winBig, volume: effectiveVolume)
            HapticManager.shared.playWinBigHaptic()
        case .loseSigh:
            playSystemSound(.loseSigh, volume: effectiveVolume)
            HapticManager.shared.playLoseHaptic()
        case .gwangHit:
            playSystemSound(.gwangHit, volume: effectiveVolume)
            HapticManager.shared.playBrightHaptic()
        case .godori:
            playSystemSound(.godori, volume: effectiveVolume)
            HapticManager.shared.playGodoriHaptic()
        case .ppuk:
            playSystemSound(.ppuk, volume: effectiveVolume)
            HapticManager.shared.playPpukHaptic()
        case .ssul:
            playSystemSound(.ssul, volume: effectiveVolume)
            HapticManager.shared.playSsulHaptic()
        case .jjok:
            playSystemSound(.jjok, volume: effectiveVolume)
            HapticManager.shared.playJjokHaptic()
        }
    }

    // MARK: - 시스템 사운드 재생 (톤 제너레이터 기반)

    private func playSystemSound(_ type: SystemSoundType, volume: Float) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.generateAndPlayTone(for: type, volume: volume)
        }
    }

    /// 프로그래매틱 사운드 생성 (에셋 파일 없이 사운드 합성)
    private func generateAndPlayTone(for type: SystemSoundType, volume: Float) {
        let sampleRate: Double = 44100
        let params = type.toneParameters

        let frameCount = Int(sampleRate * params.duration)
        var samples = [Float](repeating: 0, count: frameCount)

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0

            // 기본 파형 생성
            for (freq, amp) in params.frequencies {
                let phase = 2.0 * Double.pi * freq * t
                switch params.waveform {
                case .sine:
                    sample += Float(sin(phase) * amp)
                case .square:
                    sample += Float((sin(phase) > 0 ? 1.0 : -1.0) * amp)
                case .noise:
                    sample += Float.random(in: -1...1) * Float(amp)
                case .triangle:
                    sample += Float(2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0) * Float(amp)
                }
            }

            // 엔벨로프 적용 (ADSR)
            let envelope = params.envelope.value(at: t, totalDuration: params.duration)
            sample *= Float(envelope)

            samples[i] = sample * volume
        }

        // AVAudioPlayer로 재생
        playPCMData(samples: samples, sampleRate: sampleRate)
    }

    private func playPCMData(samples: [Float], sampleRate: Double) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)

        let channelData = buffer.floatChannelData![0]
        for i in 0..<samples.count {
            channelData[i] = samples[i]
        }

        // WAV 데이터로 변환해서 AVAudioPlayer로 재생
        if let data = bufferToWAVData(buffer: buffer, sampleRate: sampleRate) {
            DispatchQueue.main.async {
                do {
                    let player = try AVAudioPlayer(data: data)
                    player.prepareToPlay()
                    player.play()
                    // 재생 완료까지 레퍼런스 유지
                    let key = UUID().uuidString
                    self.sfxPlayers[key] = player
                    DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                        self.sfxPlayers.removeValue(forKey: key)
                    }
                } catch {
                    print("Sound playback error: \(error)")
                }
            }
        }
    }

    private func bufferToWAVData(buffer: AVAudioPCMBuffer, sampleRate: Double) -> Data? {
        let channelData = buffer.floatChannelData![0]
        let frameLength = Int(buffer.frameLength)

        var data = Data()

        // WAV header
        let dataSize = frameLength * 2 // 16-bit samples
        let fileSize = 36 + dataSize

        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // chunk size
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // mono
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Array($0) }) // byte rate
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) }) // block align
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) }) // bits per sample
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        // Convert float samples to 16-bit PCM
        for i in 0..<frameLength {
            let clamped = max(-1.0, min(1.0, channelData[i]))
            let intSample = Int16(clamped * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
        }

        return data
    }

    // MARK: - BGM

    func playBGM(named: String) {
        // BGM은 에셋 파일이 있을 때 사용
        // MVP에서는 톤 기반 효과음만 사용
    }

    func stopBGM() {
        bgmPlayer?.stop()
    }

    private func updateVolumes() {
        bgmPlayer?.volume = masterVolume * bgmVolume
    }
}

// MARK: - Sound Parameters

enum Waveform {
    case sine, square, noise, triangle
}

struct ADSREnvelope {
    let attack: Double
    let decay: Double
    let sustain: Double
    let release: Double

    func value(at time: Double, totalDuration: Double) -> Double {
        if time < attack {
            return time / attack
        } else if time < attack + decay {
            let decayProgress = (time - attack) / decay
            return 1.0 - (1.0 - sustain) * decayProgress
        } else if time < totalDuration - release {
            return sustain
        } else {
            let releaseProgress = (time - (totalDuration - release)) / release
            return sustain * (1.0 - releaseProgress)
        }
    }

    static let sharp = ADSREnvelope(attack: 0.005, decay: 0.05, sustain: 0.3, release: 0.1)
    static let soft = ADSREnvelope(attack: 0.02, decay: 0.1, sustain: 0.5, release: 0.2)
    static let punch = ADSREnvelope(attack: 0.001, decay: 0.03, sustain: 0.1, release: 0.05)
    static let long = ADSREnvelope(attack: 0.01, decay: 0.2, sustain: 0.6, release: 0.4)
}

struct ToneParameters {
    let frequencies: [(Double, Double)] // (frequency, amplitude) pairs
    let duration: Double
    let waveform: Waveform
    let envelope: ADSREnvelope
}

enum SystemSoundType {
    case cardDeal, cardPlay, cardMatch, cardFlip
    case goCall, stopCall
    case bomb, shake
    case winCheer, winBig, loseSigh
    case gwangHit, godori
    case ppuk, ssul, jjok

    var toneParameters: ToneParameters {
        switch self {
        case .cardDeal:
            return ToneParameters(
                frequencies: [(800, 0.3), (1200, 0.15)],
                duration: 0.06,
                waveform: .noise,
                envelope: .punch
            )
        case .cardPlay:
            return ToneParameters(
                frequencies: [(400, 0.5), (600, 0.25)],
                duration: 0.08,
                waveform: .noise,
                envelope: .sharp
            )
        case .cardMatch:
            return ToneParameters(
                frequencies: [(523, 0.4), (659, 0.3), (784, 0.2)],
                duration: 0.15,
                waveform: .sine,
                envelope: .sharp
            )
        case .cardFlip:
            return ToneParameters(
                frequencies: [(600, 0.25), (900, 0.15)],
                duration: 0.1,
                waveform: .triangle,
                envelope: .sharp
            )
        case .goCall:
            // 상승하는 밝은 톤
            return ToneParameters(
                frequencies: [(440, 0.5), (554, 0.4), (659, 0.3)],
                duration: 0.3,
                waveform: .sine,
                envelope: .soft
            )
        case .stopCall:
            // 안정적인 하강 톤
            return ToneParameters(
                frequencies: [(659, 0.4), (523, 0.5)],
                duration: 0.25,
                waveform: .sine,
                envelope: .soft
            )
        case .bomb:
            // 폭발음 - 저주파 + 노이즈
            return ToneParameters(
                frequencies: [(80, 0.7), (120, 0.5), (200, 0.3)],
                duration: 0.4,
                waveform: .noise,
                envelope: ADSREnvelope(attack: 0.001, decay: 0.1, sustain: 0.2, release: 0.3)
            )
        case .shake:
            return ToneParameters(
                frequencies: [(300, 0.3), (500, 0.2), (700, 0.15)],
                duration: 0.2,
                waveform: .triangle,
                envelope: .sharp
            )
        case .winCheer:
            // 승리 팡파레
            return ToneParameters(
                frequencies: [(523, 0.4), (659, 0.4), (784, 0.3), (1047, 0.2)],
                duration: 0.6,
                waveform: .sine,
                envelope: .long
            )
        case .winBig:
            // 대박 승리
            return ToneParameters(
                frequencies: [(523, 0.5), (659, 0.5), (784, 0.4), (1047, 0.3), (1318, 0.2)],
                duration: 1.0,
                waveform: .sine,
                envelope: ADSREnvelope(attack: 0.02, decay: 0.3, sustain: 0.5, release: 0.5)
            )
        case .loseSigh:
            // 패배 하강음
            return ToneParameters(
                frequencies: [(440, 0.3), (330, 0.4), (262, 0.3)],
                duration: 0.5,
                waveform: .sine,
                envelope: ADSREnvelope(attack: 0.05, decay: 0.1, sustain: 0.4, release: 0.3)
            )
        case .gwangHit:
            // 광 획득 - 밝은 차임
            return ToneParameters(
                frequencies: [(880, 0.4), (1109, 0.3), (1319, 0.3), (1760, 0.2)],
                duration: 0.4,
                waveform: .sine,
                envelope: .soft
            )
        case .godori:
            // 고도리 - 새소리 느낌
            return ToneParameters(
                frequencies: [(1200, 0.3), (1500, 0.25), (1800, 0.2), (2000, 0.15)],
                duration: 0.5,
                waveform: .sine,
                envelope: ADSREnvelope(attack: 0.01, decay: 0.15, sustain: 0.3, release: 0.3)
            )
        case .ppuk:
            // 뻑 - 짧은 경고음
            return ToneParameters(
                frequencies: [(200, 0.5), (150, 0.4)],
                duration: 0.15,
                waveform: .square,
                envelope: .punch
            )
        case .ssul:
            // 쓸 - 쓸어가는 느낌
            return ToneParameters(
                frequencies: [(400, 0.3), (800, 0.2), (1200, 0.15)],
                duration: 0.3,
                waveform: .noise,
                envelope: ADSREnvelope(attack: 0.01, decay: 0.05, sustain: 0.3, release: 0.2)
            )
        case .jjok:
            // 쪽 - 깨끗한 매칭 소리
            return ToneParameters(
                frequencies: [(660, 0.4), (880, 0.35), (1100, 0.25)],
                duration: 0.2,
                waveform: .sine,
                envelope: .sharp
            )
        }
    }
}
