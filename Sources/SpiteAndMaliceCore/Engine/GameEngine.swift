import Foundation

public struct PlayerConfiguration: Equatable {
    public let name: String
    public let isHuman: Bool

    public init(name: String, isHuman: Bool) {
        self.name = name
        self.isHuman = isHuman
    }
}

public struct PlayResult: Equatable {
    public let playedCard: PlayedCard
    public let fromOrigin: CardOrigin
    public let pileIndex: Int
    public let didCompleteBuild: Bool
    public let clearedCards: [Card]
    public let didEmptyStock: Bool
}

public struct DiscardResult: Equatable {
    public let discardedCard: Card
    public let toPileIndex: Int
}

public enum EngineError: Error, Equatable, LocalizedError {
    case invalidPlayerCount
    case notPlayersTurn
    case invalidOrigin
    case invalidTarget
    case invalidPhase
    case noCardAvailable
    case cardNotPlayable
    case discardRequiresHandCard

    public var errorDescription: String? {
        switch self {
        case .invalidPlayerCount:
            return "The game requires at least two players."
        case .notPlayersTurn:
            return "It is not that player's turn."
        case .invalidOrigin:
            return "The selected card cannot be played."
        case .invalidTarget:
            return "The target pile is invalid."
        case .invalidPhase:
            return "The action is not allowed in the current phase."
        case .noCardAvailable:
            return "There is no card available from the requested source."
        case .cardNotPlayable:
            return "That card cannot be played on the chosen build pile."
        case .discardRequiresHandCard:
            return "You must discard from your hand."
        }
    }
}

public struct GameEngine {
    public static let handLimit = 5
    public static let discardPileSlots = 4
    public static let stockPileCount = 20
    public static let numberOfDecks = 2
    public static let buildPileCount = 4

    public init() {}

    public func newGame(
        with players: [PlayerConfiguration],
        seed: UInt64? = nil
    ) throws -> GameState {
        guard players.count >= 2 else {
            throw EngineError.invalidPlayerCount
        }

        var deck = makeDeck(deckCount: Self.numberOfDecks)
        if var seeded = seed.map({ SeededGenerator(seed: $0) }) {
            deck.shuffle(using: &seeded)
        } else {
            var system = SystemRandomNumberGenerator()
            deck.shuffle(using: &system)
        }

        var dealtPlayers: [Player] = []
        for configuration in players {
            var stock = drawCards(count: Self.stockPileCount, from: &deck)
            stock.reverse()
            dealtPlayers.append(
                Player(
                    name: configuration.name,
                    isHuman: configuration.isHuman,
                    stockPile: stock,
                    discardPiles: Array(repeating: [], count: Self.discardPileSlots),
                    hand: [],
                    score: 0
                )
            )
        }

        let state = GameState(
            players: dealtPlayers,
            buildPiles: Array(repeating: BuildPile(), count: Self.buildPileCount),
            drawPile: deck,
            recyclePile: [],
            currentPlayerIndex: 0,
            turn: 1,
            status: .playing,
            phase: .drawing,
            activityLog: [GameEvent(message: "A new game has begun.")]
        )
        return state
    }

    public func prepareTurn(state: inout GameState) {
        guard state.status == .playing else { return }
        guard state.phase == .drawing else { return }
        let drawn = drawToHand(playerIndex: state.currentPlayerIndex, state: &state)
        if drawn > 0 {
            state.activityLog.append(GameEvent(message: "\(state.currentPlayer.name) draws \(drawn) card\(drawn == 1 ? "" : "s")."))
        }
        state.phase = .acting
    }

    public func drawToHand(playerIndex: Int, state: inout GameState) -> Int {
        guard state.players.indices.contains(playerIndex) else { return 0 }
        var drawnCount = 0
        refillDrawPileIfNeeded(state: &state)
        while state.players[playerIndex].hand.count < Self.handLimit {
            guard let card = drawSingleCard(state: &state) else { break }
            state.players[playerIndex].hand.append(card)
            drawnCount += 1
        }
        return drawnCount
    }

    public func play(
        origin: CardOrigin,
        toBuildPile pileIndex: Int,
        state: inout GameState
    ) throws -> PlayResult {
        guard state.status == .playing else { throw EngineError.invalidPhase }
        guard origin.playerIndex == state.currentPlayerIndex else { throw EngineError.notPlayersTurn }
        guard state.phase == .acting || state.phase == .drawing else { throw EngineError.invalidPhase }
        guard state.buildPiles.indices.contains(pileIndex) else { throw EngineError.invalidTarget }

        let playerIndex = origin.playerIndex
        guard state.players.indices.contains(playerIndex) else {
            throw EngineError.invalidOrigin
        }

        var player = state.players[playerIndex]
        let sourceCard: Card
        switch origin {
        case .stock:
            guard let card = player.stockPile.last else {
                throw EngineError.noCardAvailable
            }
            sourceCard = card
        case let .hand(_, handIndex):
            guard player.hand.indices.contains(handIndex) else {
                throw EngineError.noCardAvailable
            }
            sourceCard = player.hand[handIndex]
        case let .discard(_, discardIndex, depth):
            guard depth == 0 else { throw EngineError.invalidOrigin }
            guard player.discardPiles.indices.contains(discardIndex), let card = player.discardPiles[discardIndex].last else {
                throw EngineError.noCardAvailable
            }
            sourceCard = card
        }

        var targetPile = state.buildPiles[pileIndex]
        let requiredValue = targetPile.nextRequiredValue
        let resolvedValue: CardValue
        if sourceCard.isWild {
            resolvedValue = requiredValue
        } else if sourceCard.value == requiredValue {
            resolvedValue = sourceCard.value
        } else {
            throw EngineError.cardNotPlayable
        }
        let playedCard = PlayedCard(card: sourceCard, resolvedValue: resolvedValue)
        targetPile.append(playedCard)

        var didPlayFromHand = false
        switch origin {
        case .stock:
            player.stockPile.removeLast()
            player.completedStockCards += 1
        case let .hand(_, handIndex):
            player.hand.remove(at: handIndex)
            didPlayFromHand = true
        case let .discard(_, discardIndex, _):
            player.discardPiles[discardIndex].removeLast()
        }
        player.cardsPlayed += 1
        state.players[playerIndex] = player

        if didPlayFromHand,
           state.status == .playing,
           state.phase == .acting,
           state.players[playerIndex].hand.isEmpty {
            let drawn = drawToHand(playerIndex: playerIndex, state: &state)
            if drawn > 0 {
                state.activityLog.append(
                    GameEvent(
                        message: "\(state.currentPlayer.name) draws \(drawn) fresh card\(drawn == 1 ? "" : "s") to refill their hand."
                    )
                )
            }
        }

        var clearedCards: [Card] = []
        var didComplete = false
        if targetPile.isComplete {
            clearedCards = targetPile.reset().map { $0.card }
            state.recyclePile.append(contentsOf: clearedCards)
            didComplete = true
            state.activityLog.append(GameEvent(message: "Build pile \(pileIndex + 1) was completed."))
        }
        state.buildPiles[pileIndex] = targetPile

        var didEmptyStock = false
        if case .stock = origin {
            if player.stockPile.isEmpty {
                didEmptyStock = true
                state.activityLog.append(GameEvent(message: "\(state.currentPlayer.name) emptied their stock pile!"))
                state.status = .finished(winner: state.currentPlayer.id)
                state.phase = .waiting
            }
        }

        if state.status == .playing {
            state.phase = .acting
        }

        if sourceCard.isWild, sourceCard.value == .king, resolvedValue != .king {
            state.activityLog.append(
                GameEvent(
                    message: "\(state.currentPlayer.name) plays a King as \(resolvedValue.accessibilityLabel) to build pile \(pileIndex + 1)."
                )
            )
        } else {
            state.activityLog.append(
                GameEvent(message: "\(state.currentPlayer.name) plays \(sourceCard.displayName) to build pile \(pileIndex + 1).")
            )
        }

        return PlayResult(
            playedCard: playedCard,
            fromOrigin: origin,
            pileIndex: pileIndex,
            didCompleteBuild: didComplete,
            clearedCards: clearedCards,
            didEmptyStock: didEmptyStock
        )
    }

    public func discard(
        handIndex: Int,
        toDiscardPile discardIndex: Int,
        state: inout GameState
    ) throws -> DiscardResult {
        guard state.status == .playing else { throw EngineError.invalidPhase }
        guard state.phase == .acting || state.phase == .discarding else { throw EngineError.invalidPhase }
        guard state.currentPlayer.hand.indices.contains(handIndex) else { throw EngineError.noCardAvailable }
        guard state.currentPlayer.discardPiles.indices.contains(discardIndex) else { throw EngineError.invalidTarget }

        var player = state.currentPlayer
        let card = player.hand.remove(at: handIndex)
        player.discardPiles[discardIndex].append(card)
        player.cardsDiscarded += 1
        state.players[state.currentPlayerIndex] = player
        state.phase = .waiting
        state.activityLog.append(GameEvent(message: "\(player.name) discards \(card.displayName) to pile \(discardIndex + 1)."))
        return DiscardResult(discardedCard: card, toPileIndex: discardIndex)
    }

    public func advanceTurn(state: inout GameState) {
        guard state.status == .playing else { return }
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.players.count
        state.turn += state.currentPlayerIndex == 0 ? 1 : 0
        state.phase = .drawing
    }

    public func refillDrawPileIfNeeded(state: inout GameState) {
        if state.drawPile.isEmpty && !state.recyclePile.isEmpty {
            var rng = SystemRandomNumberGenerator()
            state.drawPile = state.recyclePile
            state.recyclePile.removeAll()
            state.drawPile.shuffle(using: &rng)
            state.activityLog.append(GameEvent(message: "The draw pile has been refreshed."))
        }
    }

    private func drawCards(count: Int, from deck: inout [Card]) -> [Card] {
        guard count > 0 else { return [] }
        var cards: [Card] = []
        for _ in 0..<count {
            guard let card = deck.popLast() else { break }
            cards.append(card)
        }
        return cards
    }

    private func drawSingleCard(state: inout GameState) -> Card? {
        if state.drawPile.isEmpty {
            refillDrawPileIfNeeded(state: &state)
        }
        return state.drawPile.popLast()
    }

    private func makeDeck(deckCount: Int) -> [Card] {
        var deck: [Card] = []
        for _ in 0..<deckCount {
            for value in CardValue.allCases {
                for _ in 0..<4 {
                    deck.append(Card(value: value))
                }
            }
        }
        return deck
    }
}
