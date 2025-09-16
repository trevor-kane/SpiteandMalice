#if canImport(SwiftUI)
import Foundation
import SwiftUI
import SpiteAndMaliceCore

@MainActor
final class GameViewModel: ObservableObject {
    struct CardSelection: Equatable {
        let origin: CardOrigin
        let card: Card
    }

    struct Hint: Equatable {
        let message: String
        let suggestedOrigin: CardOrigin?
        let suggestedPileIndex: Int?
    }

    @Published private(set) var state: GameState
    @Published var selection: CardSelection?
    @Published var hint: Hint?
    @Published var statusBanner: String = ""
    @Published var isAITakingTurn: Bool = false
    @Published var showsHelp: Bool = false

    private let engine = GameEngine()
    private var aiTask: Task<Void, Never>?

    init() {
        state = GameState.empty()
        startNewGame()
    }

    deinit {
        aiTask?.cancel()
    }

    func startNewGame(seed: UInt64? = nil) {
        aiTask?.cancel()
        do {
            state = try engine.newGame(
                with: [
                    PlayerConfiguration(name: "You", isHuman: true),
                    PlayerConfiguration(name: "Rival", isHuman: false)
                ],
                seed: seed
            )
            selection = nil
            hint = nil
            statusBanner = "Good luck! Empty your stock pile first to win."
            engine.prepareTurn(state: &state)
            updateStatusBanner()
            if !state.currentPlayer.isHuman {
                scheduleAITurn()
            }
        } catch {
            state = GameState.empty()
            statusBanner = "Unable to start game: \(error.localizedDescription)"
        }
    }

    func selectHandCard(at index: Int) {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard state.phase == .acting else { return }
        guard let card = state.players[state.currentPlayerIndex].hand[safe: index] else { return }
        selection = CardSelection(origin: .hand(playerIndex: state.currentPlayerIndex, handIndex: index), card: card)
        hint = nil
    }

    func selectStockCard() {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard let card = state.players[state.currentPlayerIndex].stockTopCard else { return }
        selection = CardSelection(origin: .stock(playerIndex: state.currentPlayerIndex), card: card)
        hint = nil
    }

    func selectDiscardCard(pileIndex: Int) {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard state.phase == .acting else { return }
        guard let card = state.players[state.currentPlayerIndex].discardPiles[safe: pileIndex]?.last else { return }
        selection = CardSelection(origin: .discard(playerIndex: state.currentPlayerIndex, pileIndex: pileIndex, depth: 0), card: card)
        hint = nil
    }

    func clearSelection() {
        selection = nil
    }

    func playSelectedCard(on pileIndex: Int) {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard let selection else { return }
        do {
            _ = try engine.play(origin: selection.origin, toBuildPile: pileIndex, state: &state)
            self.selection = nil
            hint = nil
            updateStatusBanner()
        } catch {
            statusBanner = error.localizedDescription
        }
    }

    func discardSelectedCard(to discardIndex: Int) {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard let selection, case let .hand(_, handIndex) = selection.origin else {
            statusBanner = "Select a card from your hand to discard."
            return
        }
        do {
            _ = try engine.discard(handIndex: handIndex, toDiscardPile: discardIndex, state: &state)
            self.selection = nil
            hint = nil
            updateStatusBanner()
        } catch {
            statusBanner = error.localizedDescription
        }
    }

    func handleDiscardTap(_ index: Int) {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        if let selection, case .hand = selection.origin {
            discardSelectedCard(to: index)
        } else {
            selectDiscardCard(pileIndex: index)
        }
    }

    func endTurnIfPossible() {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard state.phase == .waiting else {
            statusBanner = "Discard one card to end your turn."
            return
        }
        advanceToNextPlayer()
    }

    func provideHint() {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }

        if let suggestion = bestPlay(forPlayerAt: state.currentPlayerIndex) {
            let cardName = suggestion.card.displayName
            let pileName = suggestion.pileIndex + 1
            hint = Hint(
                message: "Play \(cardName) onto build pile \(pileName).",
                suggestedOrigin: suggestion.origin,
                suggestedPileIndex: suggestion.pileIndex
            )
            selection = CardSelection(origin: suggestion.origin, card: suggestion.card)
        } else if let discardSuggestion = bestDiscard(forPlayerAt: state.currentPlayerIndex) {
            hint = Hint(
                message: "No plays available. Discard \(discardSuggestion.card.displayName) onto pile \(discardSuggestion.discardIndex + 1).",
                suggestedOrigin: .hand(playerIndex: state.currentPlayerIndex, handIndex: discardSuggestion.handIndex),
                suggestedPileIndex: nil
            )
            selection = CardSelection(
                origin: .hand(playerIndex: state.currentPlayerIndex, handIndex: discardSuggestion.handIndex),
                card: discardSuggestion.card
            )
        } else {
            hint = Hint(message: "No available moves.", suggestedOrigin: nil, suggestedPileIndex: nil)
        }
    }

    func isValidTarget(for pileIndex: Int) -> Bool {
        guard let selection else { return false }
        guard state.buildPiles.indices.contains(pileIndex) else { return false }
        let pile = state.buildPiles[pileIndex]
        return canPlay(card: selection.card, on: pile)
    }

    func discardTitle(for index: Int) -> String {
        "Discard \(index + 1)"
    }

    func buildPileTitle(for index: Int) -> String {
        "Build \(index + 1)"
    }

    func activityLog() -> [GameEvent] {
        state.activityLog.suffix(6)
    }

    private func advanceToNextPlayer() {
        selection = nil
        hint = nil
        engine.advanceTurn(state: &state)
        engine.prepareTurn(state: &state)
        updateStatusBanner()
        if state.currentPlayer.isHuman {
            statusBanner = "Your turn. Play or discard."
        } else {
            scheduleAITurn()
        }
    }

    private func scheduleAITurn() {
        aiTask?.cancel()
        aiTask = Task { [weak self] in
            guard let self else { return }
            guard self.state.status == .playing else { return }
            self.isAITakingTurn = true
            if self.state.phase == .drawing {
                self.engine.prepareTurn(state: &self.state)
                self.updateStatusBanner()
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
            while !Task.isCancelled {
                guard let play = self.bestPlay(forPlayerAt: self.state.currentPlayerIndex) else { break }
                do {
                    _ = try self.engine.play(origin: play.origin, toBuildPile: play.pileIndex, state: &self.state)
                    self.updateStatusBanner()
                } catch {
                    break
                }
                try? await Task.sleep(nanoseconds: 350_000_000)
                if self.state.status != .playing {
                    break
                }
            }
            if self.state.status == .playing, let discard = self.bestDiscard(forPlayerAt: self.state.currentPlayerIndex) {
                do {
                    _ = try self.engine.discard(handIndex: discard.handIndex, toDiscardPile: discard.discardIndex, state: &self.state)
                    self.updateStatusBanner()
                } catch {}
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            if self.state.status == .playing {
                self.isAITakingTurn = false
                self.advanceToNextPlayer()
            } else {
                self.isAITakingTurn = false
            }
        }
    }

    private func updateStatusBanner() {
        switch state.status {
        case .idle:
            statusBanner = "Ready to play."
        case .playing:
            if state.currentPlayer.isHuman {
                statusBanner = "Your turn. Play cards to the build piles or discard."
            } else {
                statusBanner = "\(state.currentPlayer.name) is thinking..."
            }
        case let .finished(winnerID):
            if let winner = state.players.first(where: { $0.id == winnerID }) {
                statusBanner = winner.isHuman ? "You won!" : "\(winner.name) won this round."
            } else {
                statusBanner = "Game finished."
            }
        }
    }

    private func canPlay(card: Card, on pile: BuildPile) -> Bool {
        let required = pile.nextRequiredValue
        if card.isWild { return true }
        return card.value == required
    }

    private func bestPlay(forPlayerAt index: Int) -> (origin: CardOrigin, card: Card, pileIndex: Int)? {
        guard state.players.indices.contains(index) else { return nil }
        let player = state.players[index]

        if let stockCard = player.stockTopCard {
            if let pileIndex = firstPlayablePile(for: stockCard) {
                return (.stock(playerIndex: index), stockCard, pileIndex)
            }
        }

        for (handIndex, card) in player.hand.enumerated() {
            if let pileIndex = firstPlayablePile(for: card) {
                return (.hand(playerIndex: index, handIndex: handIndex), card, pileIndex)
            }
        }

        for (discardIndex, pile) in player.discardPiles.enumerated() {
            guard let card = pile.last else { continue }
            if let pileIndex = firstPlayablePile(for: card) {
                return (.discard(playerIndex: index, pileIndex: discardIndex, depth: 0), card, pileIndex)
            }
        }
        return nil
    }

    private func bestDiscard(forPlayerAt index: Int) -> (handIndex: Int, discardIndex: Int, card: Card)? {
        guard state.players.indices.contains(index) else { return nil }
        let player = state.players[index]
        guard !player.hand.isEmpty else { return nil }

        // Prefer discarding the highest non-critical card.
        let sorted = player.hand.enumerated().sorted { lhs, rhs in
            lhs.element.value.rawValue > rhs.element.value.rawValue
        }
        guard let candidate = sorted.first else { return nil }
        let discardIndex = player.discardPiles.enumerated().min { lhs, rhs in
            lhs.element.count < rhs.element.count
        }?.offset ?? 0
        return (candidate.offset, discardIndex, candidate.element)
    }

    private func firstPlayablePile(for card: Card) -> Int? {
        state.buildPiles.enumerated().first { _, pile in
            canPlay(card: card, on: pile)
        }?.offset
    }
}
#endif
