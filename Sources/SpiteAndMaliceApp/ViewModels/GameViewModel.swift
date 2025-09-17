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
        struct Recommendation: Equatable, Identifiable {
            let id = UUID()
            let rank: Int
            let detail: String

            static func == (lhs: Recommendation, rhs: Recommendation) -> Bool {
                lhs.rank == rhs.rank && lhs.detail == rhs.detail
            }
        }

        let message: String
        let suggestedOrigin: CardOrigin?
        let suggestedPileIndex: Int?
        let recommendations: [Recommendation]
    }

    struct PlayerSummary: Identifiable, Equatable {
        let id: UUID
        let name: String
        let isHuman: Bool
        let stockRemaining: Int
        let discardCardCount: Int
        let handCount: Int
        let completedStockCards: Int
        let cardsPlayed: Int
        let cardsDiscarded: Int
        let kingsPlayed: Int
        let isWinner: Bool
    }

    struct GameSummary: Equatable {
        let winner: PlayerSummary
        let totalTurns: Int
        let buildPilesCompleted: Int
        let players: [PlayerSummary]
    }

    @Published private(set) var state: GameState {
        didSet { updateUndoAvailability() }
    }
    @Published var selection: CardSelection?
    @Published var hint: Hint?
    @Published private(set) var isHintPinned: Bool = false
    @Published var statusBanner: String = ""
    @Published var isAITakingTurn: Bool = false
    @Published private(set) var canUndoTurn: Bool = false

    private let engine = GameEngine()
    private var aiTask: Task<Void, Never>?
    private var pendingAdvanceTask: Task<Void, Never>?
    private var undoStack: [GameState] = [] {
        didSet { updateUndoAvailability() }
    }
    private var hasPlayedStockThisTurn: Bool = false {
        didSet { updateUndoAvailability() }
    }

    init() {
        state = GameState.empty()
        startNewGame()
    }

    deinit {
        aiTask?.cancel()
        pendingAdvanceTask?.cancel()
    }

    func startNewGame(seed: UInt64? = nil) {
        aiTask?.cancel()
        pendingAdvanceTask?.cancel()
        pendingAdvanceTask = nil
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
            isHintPinned = false
            statusBanner = "Good luck! Empty your stock pile first to win."
            engine.prepareTurn(state: &state)
            prepareUndoForCurrentPlayer()
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
        if selection?.origin == .hand(playerIndex: state.currentPlayerIndex, handIndex: index), selection?.card.id == card.id {
            selection = nil
        } else {
            selection = CardSelection(origin: .hand(playerIndex: state.currentPlayerIndex, handIndex: index), card: card)
        }
        clearHintUnlessPinned()
    }

    func selectStockCard() {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard let card = state.players[state.currentPlayerIndex].stockTopCard else { return }
        if selection?.origin == .stock(playerIndex: state.currentPlayerIndex), selection?.card.id == card.id {
            selection = nil
        } else {
            selection = CardSelection(origin: .stock(playerIndex: state.currentPlayerIndex), card: card)
        }
        clearHintUnlessPinned()
    }

    func selectDiscardCard(pileIndex: Int) {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard state.phase == .acting else { return }
        guard let card = state.players[state.currentPlayerIndex].discardPiles[safe: pileIndex]?.last else { return }
        if selection?.origin == .discard(playerIndex: state.currentPlayerIndex, pileIndex: pileIndex, depth: 0),
           selection?.card.id == card.id {
            selection = nil
        } else {
            selection = CardSelection(origin: .discard(playerIndex: state.currentPlayerIndex, pileIndex: pileIndex, depth: 0), card: card)
        }
        clearHintUnlessPinned()
    }

    func clearSelection() {
        selection = nil
    }

    func playSelectedCard(on pileIndex: Int) {
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard let selection else { return }
        let origin = selection.origin
        let previousState = state
        do {
            _ = try engine.play(origin: origin, toBuildPile: pileIndex, state: &state)
            self.selection = nil
            clearHintUnlessPinned()
            if case .stock = origin {
                undoStack.removeAll()
                hasPlayedStockThisTurn = true
            } else if state.status == .playing && !hasPlayedStockThisTurn {
                undoStack.append(previousState)
            }
            updateStatusBanner()
            if state.status == .playing, state.currentPlayer.isHuman {
                statusBanner = "Card played. Continue your turn."
            }
            refreshPinnedHint()
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
        let previousState = state
        do {
            _ = try engine.discard(handIndex: handIndex, toDiscardPile: discardIndex, state: &state)
            self.selection = nil
            clearHintUnlessPinned()
            if state.status == .playing && !hasPlayedStockThisTurn {
                undoStack.append(previousState)
            }
            updateStatusBanner()
            if state.status == .playing {
                statusBanner = "Card discarded. Passing the turn..."
                scheduleAutomaticTurnAdvance()
            }
            refreshPinnedHint()
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

    func undoLastAction() {
        guard canUndoTurn else { return }
        guard state.status == .playing else { return }
        guard state.currentPlayer.isHuman else { return }
        guard let previousState = undoStack.popLast() else { return }
        pendingAdvanceTask?.cancel()
        pendingAdvanceTask = nil
        state = previousState
        selection = nil
        clearHintUnlessPinned()
        updateStatusBanner()
        statusBanner = "Last move undone. Continue your turn."
        refreshPinnedHint()
    }

    func provideHint() {
        guard state.status == .playing else { return }

        if isHintPinned {
            isHintPinned = false
            hint = nil
            selection = nil
            return
        }

        guard state.currentPlayer.isHuman else { return }

        isHintPinned = true
        refreshPinnedHint()
    }

    func isValidTarget(for pileIndex: Int) -> Bool {
        guard let selection else { return false }
        guard state.buildPiles.indices.contains(pileIndex) else { return false }
        let pile = state.buildPiles[pileIndex]
        return canPlay(card: selection.card, on: pile)
    }

    func discardTitle(for index: Int) -> String {
        "Discard"
    }

    func buildPileTitle(for index: Int) -> String {
        "Build"
    }

    func activityLog() -> [GameEvent] {
        Array(state.activityLog.suffix(8).reversed())
    }

    var gameSummary: GameSummary? {
        guard case let .finished(winnerID) = state.status,
              let _ = state.players.first(where: { $0.id == winnerID }) else {
            return nil
        }

        let buildClears = state.buildPiles.reduce(0) { $0 + $1.clearedSets }

        let playerSummaries = state.players.map { player -> PlayerSummary in
            let discardCount = player.discardPiles.reduce(0) { $0 + $1.count }
            return PlayerSummary(
                id: player.id,
                name: player.name,
                isHuman: player.isHuman,
                stockRemaining: player.stockPile.count,
                discardCardCount: discardCount,
                handCount: player.hand.count,
                completedStockCards: player.completedStockCards,
                cardsPlayed: player.cardsPlayed,
                cardsDiscarded: player.cardsDiscarded,
                kingsPlayed: player.kingsPlayed,
                isWinner: player.id == winnerID
            )
        }

        guard let winnerSummary = playerSummaries.first(where: { $0.id == winnerID }) else {
            return nil
        }

        return GameSummary(
            winner: winnerSummary,
            totalTurns: state.turn,
            buildPilesCompleted: buildClears,
            players: playerSummaries
        )
    }

    private func clearHintUnlessPinned() {
        if !isHintPinned {
            hint = nil
        }
    }

    private func refreshPinnedHint() {
        guard isHintPinned else { return }

        guard state.status == .playing else {
            hint = nil
            selection = nil
            return
        }

        guard let humanIndex = state.players.firstIndex(where: { $0.isHuman }) else {
            hint = nil
            selection = nil
            return
        }

        guard state.currentPlayerIndex == humanIndex else {
            hint = Hint(
                message: "Waiting for your turn. Tips will resume once you're up.",
                suggestedOrigin: nil,
                suggestedPileIndex: nil,
                recommendations: []
            )
            selection = nil
            return
        }

        if let payload = hintPayload(for: humanIndex) {
            hint = payload.hint
            selection = payload.selection
        } else {
            hint = Hint(
                message: "No plays available right now. Discard to set up your next turn.",
                suggestedOrigin: nil,
                suggestedPileIndex: nil,
                recommendations: []
            )
            selection = nil
        }
    }

    private func hintPayload(for playerIndex: Int) -> (hint: Hint, selection: CardSelection?)? {
        let rankedPlays = rankedPlayOptions(forPlayerAt: playerIndex)

        if let bestPlay = rankedPlays.first {
            let recommendations = Array(rankedPlays.prefix(3).enumerated().map { index, option in
                Hint.Recommendation(
                    rank: index + 1,
                    detail: recommendationDescription(for: option)
                )
            })
            let hint = Hint(
                message: playMessage(for: bestPlay),
                suggestedOrigin: bestPlay.origin,
                suggestedPileIndex: bestPlay.pileIndex,
                recommendations: recommendations
            )
            let selection = CardSelection(origin: bestPlay.origin, card: bestPlay.card)
            return (hint, selection)
        }

        if let discardSuggestion = bestDiscard(forPlayerAt: playerIndex) {
            let hint = Hint(
                message: "No plays available. Discard \(discardSuggestion.card.displayName) to \(discardPileDescription(for: discardSuggestion.discardIndex)).",
                suggestedOrigin: .hand(playerIndex: playerIndex, handIndex: discardSuggestion.handIndex),
                suggestedPileIndex: nil,
                recommendations: []
            )
            let selection = CardSelection(
                origin: .hand(playerIndex: playerIndex, handIndex: discardSuggestion.handIndex),
                card: discardSuggestion.card
            )
            return (hint, selection)
        }

        return nil
    }

    private func advanceToNextPlayer() {
        selection = nil
        clearHintUnlessPinned()
        undoStack.removeAll()
        hasPlayedStockThisTurn = false
        pendingAdvanceTask?.cancel()
        pendingAdvanceTask = nil
        engine.advanceTurn(state: &state)
        engine.prepareTurn(state: &state)
        if state.status == .playing {
            prepareUndoForCurrentPlayer()
        }
        updateStatusBanner()
        if state.status == .playing {
            if state.currentPlayer.isHuman {
                statusBanner = "Your turn. Play or discard."
            } else {
                scheduleAITurn()
            }
        }

        refreshPinnedHint()
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

    private func prepareUndoForCurrentPlayer() {
        undoStack.removeAll()
        hasPlayedStockThisTurn = false
    }

    private func scheduleAutomaticTurnAdvance() {
        pendingAdvanceTask?.cancel()
        pendingAdvanceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard let self, !Task.isCancelled else { return }
            await MainActor.run {
                self.finishTurnAfterDiscard()
            }
        }
    }

    @MainActor
    private func finishTurnAfterDiscard() {
        pendingAdvanceTask = nil
        guard state.status == .playing else { return }
        guard state.phase == .waiting else { return }
        advanceToNextPlayer()
    }

    private func updateUndoAvailability() {
        canUndoTurn = !undoStack.isEmpty && !hasPlayedStockThisTurn && state.status == .playing && state.currentPlayer.isHuman
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
        rankedPlayOptions(forPlayerAt: index).first.map { option in
            (option.origin, option.card, option.pileIndex)
        }
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

    private func rankedPlayOptions(forPlayerAt index: Int) -> [PlayOption] {
        guard state.players.indices.contains(index) else { return [] }
        let player = state.players[index]
        var options: [PlayOption] = []
        var order: Int = 0

        if let stockCard = player.stockTopCard {
            let piles = playablePiles(for: stockCard)
            for pileIndex in piles {
                options.append(
                    PlayOption(
                        origin: .stock(playerIndex: index),
                        card: stockCard,
                        pileIndex: pileIndex,
                        priority: 0,
                        order: order
                    )
                )
                order += 1
            }
        }

        for (handIndex, card) in player.hand.enumerated() {
            let piles = playablePiles(for: card)
            for pileIndex in piles {
                options.append(
                    PlayOption(
                        origin: .hand(playerIndex: index, handIndex: handIndex),
                        card: card,
                        pileIndex: pileIndex,
                        priority: 1,
                        order: order
                    )
                )
                order += 1
            }
        }

        for (discardIndex, pile) in player.discardPiles.enumerated() {
            guard let card = pile.last else { continue }
            let piles = playablePiles(for: card)
            for pileIndex in piles {
                options.append(
                    PlayOption(
                        origin: .discard(playerIndex: index, pileIndex: discardIndex, depth: 0),
                        card: card,
                        pileIndex: pileIndex,
                        priority: 2,
                        order: order
                    )
                )
                order += 1
            }
        }

        return options.sorted { lhs, rhs in
            if lhs.priority == rhs.priority {
                if lhs.order == rhs.order {
                    return lhs.pileIndex < rhs.pileIndex
                }
                return lhs.order < rhs.order
            }
            return lhs.priority < rhs.priority
        }
    }

    private func playablePiles(for card: Card) -> [Int] {
        state.buildPiles.enumerated().compactMap { index, pile in
            canPlay(card: card, on: pile) ? index : nil
        }
    }

    private func playMessage(for option: PlayOption) -> String {
        "Play \(option.card.displayName) from \(originDescription(for: option.origin)) to \(buildPileDescription(for: option.pileIndex))."
    }

    private func recommendationDescription(for option: PlayOption) -> String {
        "\(option.card.displayName) from \(originDescription(for: option.origin)) → \(buildPileDescription(for: option.pileIndex))"
    }

    private func originDescription(for origin: CardOrigin) -> String {
        switch origin {
        case .stock:
            return "your stock pile"
        case .hand:
            return "your hand"
        case let .discard(_, pileIndex, _):
            return discardPileDescription(for: pileIndex)
        }
    }

    private func discardPileDescription(for index: Int) -> String {
        let descriptors = ["left", "left-center", "right-center", "right"]
        if index < descriptors.count {
            return "your \(descriptors[index]) discard pile"
        }
        return "one of your discard piles"
    }

    private func buildPileDescription(for index: Int) -> String {
        let descriptors = ["the left build pile", "the left-center build pile", "the right-center build pile", "the right build pile"]
        if index < descriptors.count {
            return descriptors[index]
        }
        return "a build pile"
    }

    private struct PlayOption {
        let origin: CardOrigin
        let card: Card
        let pileIndex: Int
        let priority: Int
        let order: Int
    }
}
#endif

