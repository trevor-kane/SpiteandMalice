import Foundation

public enum CardOrigin: Equatable, Codable {
    case stock(playerIndex: Int)
    case hand(playerIndex: Int, handIndex: Int)
    case discard(playerIndex: Int, pileIndex: Int, depth: Int)

    public var playerIndex: Int {
        switch self {
        case let .stock(playerIndex):
            return playerIndex
        case let .hand(playerIndex, _):
            return playerIndex
        case let .discard(playerIndex, _, _):
            return playerIndex
        }
    }
}
