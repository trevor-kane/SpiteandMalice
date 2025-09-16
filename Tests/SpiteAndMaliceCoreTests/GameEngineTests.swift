import XCTest
@testable import SpiteAndMaliceCore

final class GameEngineTests: XCTestCase {
    func testNewGameDealsStockPiles() throws {
        let engine = GameEngine()
        var state = try engine.newGame(
            with: [
                PlayerConfiguration(name: "Player", isHuman: true),
                PlayerConfiguration(name: "AI", isHuman: false)
            ],
            seed: 123
        )
        XCTAssertEqual(state.players.count, 2)
        XCTAssertEqual(state.players[0].stockPile.count, GameEngine.stockPileCount)
        XCTAssertEqual(state.players[1].stockPile.count, GameEngine.stockPileCount)
        engine.prepareTurn(state: &state)
        XCTAssertEqual(state.players[0].hand.count, GameEngine.handLimit)
        XCTAssertEqual(state.phase, .acting)
        XCTAssertEqual(state.status, .playing)
    }

    func testPlayingStockCardAdvancesBuildPile() throws {
        let engine = GameEngine()
        var state = try engine.newGame(
            with: [
                PlayerConfiguration(name: "Player", isHuman: true),
                PlayerConfiguration(name: "AI", isHuman: false)
            ],
            seed: 777
        )
        engine.prepareTurn(state: &state)
        // Force the top stock card to be an Ace so it can start a build pile.
        state.players[0].stockPile[state.players[0].stockPile.count - 1] = Card(value: .ace)
        let result = try engine.play(origin: .stock(playerIndex: 0), toBuildPile: 0, state: &state)
        XCTAssertEqual(result.playedCard.resolvedValue, .ace)
        XCTAssertEqual(state.buildPiles[0].cards.count, 1)
        XCTAssertTrue(state.players[0].stockPile.count == GameEngine.stockPileCount - 1)
    }

    func testWildCardCompletesPileAndRecycles() throws {
        let engine = GameEngine()
        var state = try engine.newGame(
            with: [
                PlayerConfiguration(name: "Player", isHuman: true),
                PlayerConfiguration(name: "AI", isHuman: false)
            ],
            seed: 101
        )
        engine.prepareTurn(state: &state)
        // Preload the build pile so it needs a Queen to complete.
        let filledValues = CardValue.buildSequence.dropLast()
        state.buildPiles[0].cards = filledValues.map { value in
            PlayedCard(card: Card(value: value), resolvedValue: value)
        }
        state.players[0].hand = [Card(value: .king)]
        _ = try engine.play(origin: .hand(playerIndex: 0, handIndex: 0), toBuildPile: 0, state: &state)
        XCTAssertTrue(state.buildPiles[0].cards.isEmpty)
        XCTAssertEqual(state.recyclePile.count, BuildPile.targetSequenceCount)
    }

    func testDiscardRequiresAvailableCard() throws {
        let engine = GameEngine()
        var state = try engine.newGame(
            with: [
                PlayerConfiguration(name: "Player", isHuman: true),
                PlayerConfiguration(name: "AI", isHuman: false)
            ],
            seed: 55
        )
        engine.prepareTurn(state: &state)
        state.players[0].hand.removeAll()
        XCTAssertThrowsError(try engine.discard(handIndex: 0, toDiscardPile: 0, state: &state)) { error in
            XCTAssertEqual(error as? EngineError, .noCardAvailable)
        }
    }
}
