import Foundation

public enum CardValue: Int, CaseIterable, Codable, Comparable {
    case ace = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case jack
    case queen
    case king

    public static let buildSequence: [CardValue] = CardValue.allCases.filter { $0 != .king }

    public static func < (lhs: CardValue, rhs: CardValue) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var label: String {
        switch self {
        case .ace:
            return "A"
        case .jack:
            return "J"
        case .queen:
            return "Q"
        case .king:
            return "K"
        default:
            return String(rawValue)
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .ace:
            return "Ace"
        case .jack:
            return "Jack"
        case .queen:
            return "Queen"
        case .king:
            return "King"
        default:
            return String(rawValue)
        }
    }

    public var nextValue: CardValue? {
        CardValue(rawValue: rawValue + 1)
    }
}

public struct Card: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let value: CardValue

    public init(id: UUID = UUID(), value: CardValue) {
        self.id = id
        self.value = value
    }

    public var isWild: Bool { value == .king }

    public var displayName: String { value.label }

    public var debugDescription: String { "Card(\(value.label))" }
}

public struct PlayedCard: Identifiable, Codable, Equatable {
    public let id: UUID
    public let card: Card
    public let resolvedValue: CardValue

    public init(card: Card, resolvedValue: CardValue) {
        self.id = UUID()
        self.card = card
        self.resolvedValue = resolvedValue
    }
}
