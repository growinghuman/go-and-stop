import Foundation

/// 게임 기록
struct GameRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let won: Bool
    let score: Int
    let goCount: Int
    let multipliers: [String]
    let aiDifficulty: String
    let brightCount: Int
    let animalCount: Int
    let ribbonCount: Int
    let junkCount: Int
    let hadGodori: Bool
    let roundsPlayed: Int

    init(
        won: Bool,
        score: Int,
        goCount: Int,
        multipliers: [String],
        aiDifficulty: AIDifficulty,
        brightCount: Int,
        animalCount: Int,
        ribbonCount: Int,
        junkCount: Int,
        hadGodori: Bool,
        roundsPlayed: Int
    ) {
        self.id = UUID()
        self.date = Date()
        self.won = won
        self.score = score
        self.goCount = goCount
        self.multipliers = multipliers
        self.aiDifficulty = aiDifficulty.rawValue
        self.brightCount = brightCount
        self.animalCount = animalCount
        self.ribbonCount = ribbonCount
        self.junkCount = junkCount
        self.hadGodori = hadGodori
        self.roundsPlayed = roundsPlayed
    }
}

/// 게임 기록 저장소
class GameRecordStore: ObservableObject {
    static let shared = GameRecordStore()

    @Published var records: [GameRecord] = []

    private let storageKey = "gameRecords"

    private init() {
        loadRecords()
    }

    func addRecord(_ record: GameRecord) {
        records.insert(record, at: 0)
        if records.count > 100 {
            records = Array(records.prefix(100))
        }
        saveRecords()
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([GameRecord].self, from: data) {
            records = decoded
        }
    }
}
