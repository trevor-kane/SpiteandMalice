import Foundation

public struct BuildPile: Identifiable, Codable, Equatable {
    public let id: UUID
    public var cards: [PlayedCard]
    public var clearedSets: Int

    public init(id: UUID = UUID(), cards: [PlayedCard] = [], clearedSets: Int = 0) {
        self.id = id
        self.cards = cards
        self.clearedSets = clearedSets
    }

    public static let targetSequenceCount = CardValue.buildSequence.count

    public var nextRequiredValue: CardValue {
        guard let last = cards.last else {
            return .ace
        }
        return last.resolvedValue.nextValue ?? .ace
    }

    public var isComplete: Bool {
        cards.count == Self.targetSequenceCount
    }

    public var topCard: PlayedCard? { cards.last }

    public mutating func append(_ playedCard: PlayedCard) {
        cards.append(playedCard)
    }

    public mutating func reset() -> [PlayedCard] {
        defer {
            cards.removeAll()
            clearedSets += 1
        }
        return cards
    }
}
