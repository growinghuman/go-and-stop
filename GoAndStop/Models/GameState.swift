import Foundation

/// 게임 진행 상태
enum GamePhase: Equatable {
    case notStarted             // 게임 시작 전
    case dealing                // 카드 배분 중
    case playerTurnSelectCard   // 플레이어: 손패에서 카드 선택
    case playerTurnSelectMatch  // 플레이어: 바닥에서 매칭 카드 선택 (2장 중 선택)
    case playerTurnFlipDeck     // 플레이어: 덱에서 카드 뒤집기
    case playerTurnFlipMatch    // 플레이어: 뒤집은 카드 매칭 선택
    case playerTurnGoStop       // 플레이어: 고/스톱 결정
    case aiTurn                 // AI 턴 진행 중
    case aiTurnGoStop           // AI: 고/스톱 결정
    case roundEnd               // 라운드 종료
    case gameOver               // 게임 종료
    case nagari                 // 나가리 (무승부)
}

/// 턴 중 발생하는 이벤트
enum TurnEvent: Equatable {
    case none
    case matched(Card, Card)            // 카드 매칭 성공
    case noMatch                        // 매칭 실패 (버림)
    case ppuk                           // 뻑
    case jjok                           // 쪽 (3장 먹기)
    case ssul                           // 쓸 (바닥 전부 쓸기)
    case bomb([Card])                   // 폭탄
    case shake([Card])                  // 흔듦
    case chongTong                      // 총통
    case godoriComplete                 // 고도리 완성
    case brightCaptured(Card)           // 광 획득
    case ribbonSetComplete(RibbonType)  // 홍단/청단/초단 완성
    case goDecision                     // 고 선언
    case stopDecision                   // 스톱 선언
}

/// 게임 전체 상태
class GameState: ObservableObject {
    @Published var phase: GamePhase = .notStarted
    @Published var humanPlayer: Player
    @Published var aiPlayer: Player
    @Published var tableCards: [Card] = []
    @Published var deck: [Card] = []
    @Published var currentTurn: PlayerID = .human
    @Published var lastEvent: TurnEvent = .none
    @Published var roundNumber: Int = 1
    @Published var isNagari: Bool = false
    @Published var nagariMultiplier: Int = 1 // 나가리 시 배수
    @Published var selectedHandCard: Card? = nil
    @Published var flippedDeckCard: Card? = nil
    @Published var matchableTableCards: [Card] = [] // 선택 가능한 바닥 카드
    @Published var turnLog: [String] = []

    // 점수
    @Published var humanScore: Int = 0
    @Published var aiScore: Int = 0

    // 최종 결과
    @Published var winner: PlayerID? = nil
    @Published var finalScore: Int = 0
    @Published var scoreMultipliers: [String] = []

    init() {
        self.humanPlayer = Player(id: .human)
        self.aiPlayer = Player(id: .ai)
    }

    func player(for id: PlayerID) -> Player {
        switch id {
        case .human: return humanPlayer
        case .ai:    return aiPlayer
        }
    }

    func opponent(of id: PlayerID) -> Player {
        switch id {
        case .human: return aiPlayer
        case .ai:    return humanPlayer
        }
    }

    /// 바닥에서 특정 월의 카드들
    func tableCardsForMonth(_ month: CardMonth) -> [Card] {
        tableCards.filter { $0.month == month }
    }

    func addLog(_ message: String) {
        turnLog.append("[\(currentTurn.displayName)] \(message)")
    }

    func reset() {
        phase = .notStarted
        humanPlayer.reset()
        aiPlayer.reset()
        tableCards.removeAll()
        deck.removeAll()
        currentTurn = .human
        lastEvent = .none
        selectedHandCard = nil
        flippedDeckCard = nil
        matchableTableCards.removeAll()
        turnLog.removeAll()
        humanScore = 0
        aiScore = 0
        winner = nil
        finalScore = 0
        scoreMultipliers.removeAll()
    }
}
