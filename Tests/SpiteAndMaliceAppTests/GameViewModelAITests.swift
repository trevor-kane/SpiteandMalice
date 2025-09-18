import XCTest
@testable import SpiteAndMaliceApp
import SpiteAndMaliceCore

final class GameViewModelAITests: XCTestCase {
    private func makeCard(_ value: CardValue) -> Card {
        Card(value: value)
    }

    private func buildPile(requiring nextValue: CardValue) -> BuildPile {
        guard nextValue != .ace else { return BuildPile() }
        let previousRaw = nextValue.rawValue - 1
        guard let previousValue = CardValue(rawValue: previousRaw) else {
            return BuildPile()
        }
        let played = PlayedCard(card: makeCard(previousValue), resolvedValue: previousValue)
        return BuildPile(cards: [played])
    }

    func testPrefersHandPlayToDiscardWhenNoStockPath() async throws {
        let handAce = makeCard(.ace)
        let discardAce = makeCard(.ace)
        let player = Player(
            name: "AI",
            isHuman: false,
            stockPile: [makeCard(.nine)],
            discardPiles: [[discardAce], [], [], []],
            hand: [handAce]
        )
        let opponent = Player(
            name: "Opponent",
            isHuman: false,
            stockPile: [makeCard(.four)],
            discardPiles: Array(repeating: [], count: 4),
            hand: []
        )
        let state = GameState(
            players: [player, opponent],
            buildPiles: [BuildPile(), BuildPile(), BuildPile(), BuildPile()],
            drawPile: [],
            recyclePile: [],
            currentPlayerIndex: 0,
            turn: 1,
            turnIdentifier: 1,
            status: .playing,
            phase: .acting
        )

        await MainActor.run {
            let viewModel = GameViewModel()
            viewModel.loadTestingState(state)

            guard let bestPlay = viewModel.bestPlay(forPlayerAt: 0) else {
                XCTFail("Expected a playable option")
                return
            }

            switch bestPlay.origin {
            case .hand:
                XCTAssertEqual(bestPlay.card.value, .ace)
            default:
                XCTFail("Expected hand play to be chosen over discard when no stock path exists")
            }
        }
    }

    func testAvoidsWildFromDiscardWithoutStockPath() async throws {
        let queen = makeCard(.queen)
        let king = makeCard(.king)
        let player = Player(
            name: "AI",
            isHuman: false,
            stockPile: [makeCard(.three)],
            discardPiles: [[king], [], [], []],
            hand: [queen]
        )
        let opponent = Player(
            name: "Opponent",
            isHuman: false,
            stockPile: [makeCard(.four)],
            discardPiles: Array(repeating: [], count: 4),
            hand: []
        )
        let buildPiles = [buildPile(requiring: .queen), BuildPile(), BuildPile(), BuildPile()]
        let state = GameState(
            players: [player, opponent],
            buildPiles: buildPiles,
            drawPile: [],
            recyclePile: [],
            currentPlayerIndex: 0,
            turn: 1,
            turnIdentifier: 1,
            status: .playing,
            phase: .acting
        )

        await MainActor.run {
            let viewModel = GameViewModel()
            viewModel.loadTestingState(state)

            guard let bestPlay = viewModel.bestPlay(forPlayerAt: 0) else {
                XCTFail("Expected a playable option")
                return
            }

            switch bestPlay.origin {
            case .hand:
                XCTAssertEqual(bestPlay.card.value, .queen)
            default:
                XCTFail("Expected hand queen to be chosen over discard king without stock path")
            }
        }
    }

    func testWildPreferredWhenItEnablesStock() async throws {
        let king = makeCard(.king)
        let five = makeCard(.five)
        let six = makeCard(.six)
        let player = Player(
            name: "AI",
            isHuman: false,
            stockPile: [six],
            discardPiles: [[five], [], [], []],
            hand: [king]
        )
        let opponent = Player(
            name: "Opponent",
            isHuman: false,
            stockPile: [makeCard(.ten)],
            discardPiles: Array(repeating: [], count: 4),
            hand: []
        )
        let buildPiles = [buildPile(requiring: .four), BuildPile(), BuildPile(), BuildPile()]
        let state = GameState(
            players: [player, opponent],
            buildPiles: buildPiles,
            drawPile: [],
            recyclePile: [],
            currentPlayerIndex: 0,
            turn: 1,
            turnIdentifier: 1,
            status: .playing,
            phase: .acting
        )

        await MainActor.run {
            let viewModel = GameViewModel()
            viewModel.loadTestingState(state)

            guard let bestPlay = viewModel.bestPlay(forPlayerAt: 0) else {
                XCTFail("Expected a playable option")
                return
            }

            switch bestPlay.origin {
            case .hand:
                XCTAssertTrue(bestPlay.card.isWild, "King should be favored when it enables stock play")
            default:
                XCTFail("Expected wild hand play that leads to stock progress")
            }
        }
    }

    func testAvoidsUnlockingOpponentStockWhenNoStockPath() async throws {
        let three = makeCard(.three)
        let ace = makeCard(.ace)
        let player = Player(
            name: "AI",
            isHuman: false,
            stockPile: [makeCard(.nine)],
            discardPiles: Array(repeating: [], count: 4),
            hand: [three, ace]
        )
        let opponent = Player(
            name: "Opponent",
            isHuman: false,
            stockPile: [makeCard(.five)],
            discardPiles: [[makeCard(.four)], [], [], []],
            hand: []
        )
        let buildPiles = [buildPile(requiring: .three), BuildPile(), BuildPile(), BuildPile()]
        let state = GameState(
            players: [player, opponent],
            buildPiles: buildPiles,
            drawPile: [],
            recyclePile: [],
            currentPlayerIndex: 0,
            turn: 1,
            turnIdentifier: 1,
            status: .playing,
            phase: .acting
        )

        await MainActor.run {
            let viewModel = GameViewModel()
            viewModel.loadTestingState(state)

            guard let bestPlay = viewModel.bestPlay(forPlayerAt: 0) else {
                XCTFail("Expected a playable option")
                return
            }

            XCTAssertEqual(bestPlay.origin.playerIndex, 0)
            XCTAssertEqual(bestPlay.card.value, .ace, "Play should block opponent instead of advancing to their discard setup")
        }
    }
}
