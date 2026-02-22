import Foundation

/// 플레이어 식별
enum PlayerID: String, Codable {
    case human = "human"
    case ai = "ai"

    var displayName: String {
        switch self {
        case .human: return "나"
        case .ai:    return "상대"
        }
    }
}

/// 플레이어 상태
class Player: ObservableObject, Identifiable {
    let id: PlayerID
    @Published var hand: [Card] = []
    @Published var capturedCards: [Card] = []
    @Published var goCount: Int = 0
    @Published var shakeCount: Int = 0
    @Published var bombCount: Int = 0

    init(id: PlayerID) {
        self.id = id
    }

    // MARK: - 획득 카드 분류

    var capturedBrights: [Card] {
        capturedCards.filter { $0.type == .bright }
    }

    var capturedAnimals: [Card] {
        capturedCards.filter { $0.type == .animal }
    }

    var capturedRibbons: [Card] {
        capturedCards.filter { $0.type == .ribbon }
    }

    var capturedJunks: [Card] {
        capturedCards.filter { $0.type == .junk || $0.type == .doubleJunk }
    }

    /// 피 총 장수 (쌍피 = 2장 가치)
    var totalJunkCount: Int {
        capturedCards.reduce(0) { sum, card in
            switch card.type {
            case .doubleJunk: return sum + 2
            case .junk:       return sum + 1
            default:          return sum
            }
        }
    }

    // MARK: - 띠 분류

    var redPoetryRibbons: [Card] {
        capturedRibbons.filter { $0.ribbonType == .redPoetry }
    }

    var bluePlainRibbons: [Card] {
        capturedRibbons.filter { $0.ribbonType == .bluePlain }
    }

    var redPlainRibbons: [Card] {
        capturedRibbons.filter { $0.ribbonType == .redPlain }
    }

    // MARK: - 고도리 카드

    var godoriCards: [Card] {
        capturedAnimals.filter { $0.isGodoriCard }
    }

    var hasGodori: Bool {
        godoriCards.count >= 3
    }

    // MARK: - 손패 관련

    func removeFromHand(_ card: Card) {
        hand.removeAll { $0.id == card.id }
    }

    func addToCaptured(_ cards: [Card]) {
        capturedCards.append(contentsOf: cards)
    }

    /// 특정 월의 카드가 손에 몇 장 있는지
    func handCardsForMonth(_ month: CardMonth) -> [Card] {
        hand.filter { $0.month == month }
    }

    // MARK: - 리셋

    func reset() {
        hand.removeAll()
        capturedCards.removeAll()
        goCount = 0
        shakeCount = 0
        bombCount = 0
    }
}
