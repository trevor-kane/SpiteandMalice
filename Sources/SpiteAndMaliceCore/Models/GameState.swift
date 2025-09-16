import Foundation

public enum GameStatus: Equatable, Codable {
    case idle
    case playing
    case finished(winner: UUID)
}

public enum TurnPhase: Equatable, Codable {
    case drawing
    case acting
    case discarding
    case waiting
}

public struct GameEvent: Identifiable, Codable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let message: String

    public init(id: UUID = UUID(), timestamp: Date = Date(), message: String) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
    }
}

public struct GameState: Codable, Equatable {
    public var players: [Player]
    public var buildPiles: [BuildPile]
    public var drawPile: [Card]
    public var recyclePile: [Card]
    public var currentPlayerIndex: Int
    public var turn: Int
    public var status: GameStatus
    public var phase: TurnPhase
    public var activityLog: [GameEvent]

    public init(
        players: [Player],
        buildPiles: [BuildPile] = Array(repeating: BuildPile(), count: 4),
        drawPile: [Card],
        recyclePile: [Card] = [],
        currentPlayerIndex: Int = 0,
        turn: Int = 1,
        status: GameStatus = .idle,
        phase: TurnPhase = .drawing,
        activityLog: [GameEvent] = []
    ) {
        self.players = players
        self.buildPiles = buildPiles
        self.drawPile = drawPile
        self.recyclePile = recyclePile
        self.currentPlayerIndex = currentPlayerIndex
        self.turn = turn
        self.status = status
        self.phase = phase
        self.activityLog = activityLog
    }

    public var currentPlayer: Player { players[currentPlayerIndex] }
}

public extension GameState {
    static func empty() -> GameState {
        GameState(
            players: [],
            buildPiles: [],
            drawPile: [],
            recyclePile: [],
            currentPlayerIndex: 0,
            turn: 0,
            status: .idle,
            phase: .waiting,
            activityLog: []
        )
    }
}
