import Foundation

public struct Player: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var isHuman: Bool
    public var stockPile: [Card]
    public var discardPiles: [[Card]]
    public var hand: [Card]
    public var score: Int
    public var completedStockCards: Int
    public var cardsPlayed: Int
    public var cardsDiscarded: Int
    public var kingsPlayed: Int

    public init(
        id: UUID = UUID(),
        name: String,
        isHuman: Bool,
        stockPile: [Card] = [],
        discardPiles: [[Card]] = Array(repeating: [], count: 4),
        hand: [Card] = [],
        score: Int = 0,
        completedStockCards: Int = 0,
        cardsPlayed: Int = 0,
        cardsDiscarded: Int = 0,
        kingsPlayed: Int = 0
    ) {
        self.id = id
        self.name = name
        self.isHuman = isHuman
        self.stockPile = stockPile
        self.discardPiles = discardPiles
        self.hand = hand
        self.score = score
        self.completedStockCards = completedStockCards
        self.cardsPlayed = cardsPlayed
        self.cardsDiscarded = cardsDiscarded
        self.kingsPlayed = kingsPlayed
    }

    public var stockTopCard: Card? { stockPile.last }

    public func discardTopCard(at index: Int) -> Card? {
        guard discardPiles.indices.contains(index) else { return nil }
        return discardPiles[index].last
    }

    public var isOutOfCards: Bool {
        stockPile.isEmpty && discardPiles.allSatisfy { $0.isEmpty } && hand.isEmpty
    }
}
