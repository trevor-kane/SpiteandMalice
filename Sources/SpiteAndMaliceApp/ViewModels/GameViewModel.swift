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
    private var turnContext: TurnContext?
    private var turnContextStack: [TurnContext] = []
    private let continuationDepthLimit = 6
    private let opponentContinuationDepth = 4

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
        turnContext = nil
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
        ensureTurnContextIsCurrent()
        let previousContext = turnContext
        do {
            _ = try engine.play(origin: origin, toBuildPile: pileIndex, state: &state)
            self.selection = nil
            clearHintUnlessPinned()
            recordPlayInTurnContext(origin: origin, card: selection.card, pileIndex: pileIndex)
            if case .stock = origin {
                undoStack.removeAll()
                turnContextStack.removeAll()
                hasPlayedStockThisTurn = true
            } else if state.status == .playing && !hasPlayedStockThisTurn {
                undoStack.append(previousState)
                if let previousContext {
                    turnContextStack.append(previousContext)
                } else if let snapshot = turnContextSnapshot(from: previousState) {
                    turnContextStack.append(snapshot)
                }
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
        ensureTurnContextIsCurrent()
        let previousContext = turnContext
        do {
            _ = try engine.discard(handIndex: handIndex, toDiscardPile: discardIndex, state: &state)
            self.selection = nil
            clearHintUnlessPinned()
            recordDiscardInTurnContext(card: selection.card, handIndex: handIndex, discardIndex: discardIndex)
            if state.status == .playing && !hasPlayedStockThisTurn {
                undoStack.append(previousState)
                if let previousContext {
                    turnContextStack.append(previousContext)
                } else if let snapshot = turnContextSnapshot(from: previousState) {
                    turnContextStack.append(snapshot)
                }
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
        let previousContext = turnContextStack.popLast()
        pendingAdvanceTask?.cancel()
        pendingAdvanceTask = nil
        state = previousState
        if let previousContext {
            turnContext = previousContext
        } else {
            turnContext = turnContextSnapshot(from: previousState)
        }
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

        if let updatedHint = hintPayload(for: humanIndex) {
            hint = updatedHint
        } else {
            hint = Hint(
                message: "No plays available right now. Discard to set up your next turn.",
                suggestedOrigin: nil,
                suggestedPileIndex: nil,
                recommendations: []
            )
        }
    }

    private func hintPayload(for playerIndex: Int) -> Hint? {
        let rankedPlays = scoredPlayOptions(forPlayerAt: playerIndex)

        if let bestPlay = rankedPlays.first {
            let recommendations = Array(rankedPlays.prefix(3).enumerated().map { index, option in
                Hint.Recommendation(
                    rank: index + 1,
                    detail: recommendationDescription(for: option)
                )
            })
            return Hint(
                message: playMessage(for: bestPlay),
                suggestedOrigin: bestPlay.origin,
                suggestedPileIndex: bestPlay.pileIndex,
                recommendations: recommendations
            )
        }

        if let discardSuggestion = bestDiscard(forPlayerAt: playerIndex) {
            return Hint(
                message: "No plays available. Discard \(discardSuggestion.card.displayName) to \(discardPileDescription(for: discardSuggestion.discardIndex)).",
                suggestedOrigin: .hand(playerIndex: playerIndex, handIndex: discardSuggestion.handIndex),
                suggestedPileIndex: nil,
                recommendations: []
            )
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
                self.beginTurnContextForCurrentPlayer()
                self.updateStatusBanner()
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
            self.ensureTurnContextIsCurrent()
            while !Task.isCancelled {
                guard let play = self.bestPlay(forPlayerAt: self.state.currentPlayerIndex) else { break }
                do {
                    _ = try self.engine.play(origin: play.origin, toBuildPile: play.pileIndex, state: &self.state)
                    self.recordPlayInTurnContext(origin: play.origin, card: play.card, pileIndex: play.pileIndex)
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
                    self.recordDiscardInTurnContext(card: discard.card, handIndex: discard.handIndex, discardIndex: discard.discardIndex)
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
        turnContextStack.removeAll()
        hasPlayedStockThisTurn = false
        beginTurnContextForCurrentPlayer()
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

    private func beginTurnContextForCurrentPlayer() {
        guard state.status == .playing else {
            turnContext = nil
            return
        }
        guard state.players.indices.contains(state.currentPlayerIndex) else {
            turnContext = nil
            return
        }
        turnContext = TurnContext(state: state, playerIndex: state.currentPlayerIndex)
    }

    private func ensureTurnContextIsCurrent() {
        guard state.status == .playing else {
            turnContext = nil
            return
        }
        guard state.players.indices.contains(state.currentPlayerIndex) else {
            turnContext = nil
            return
        }
        if let context = turnContext,
           context.turnIdentifier == state.turnIdentifier,
           context.playerIndex == state.currentPlayerIndex {
            return
        }
        turnContext = TurnContext(state: state, playerIndex: state.currentPlayerIndex)
    }

    private func recordPlayInTurnContext(origin: CardOrigin, card: Card, pileIndex: Int) {
        ensureTurnContextIsCurrent()
        turnContext?.notePlay(origin: origin, card: card, pileIndex: pileIndex)
    }

    private func recordDiscardInTurnContext(card: Card, handIndex: Int, discardIndex: Int) {
        ensureTurnContextIsCurrent()
        turnContext?.noteDiscard(card: card, handIndex: handIndex, discardIndex: discardIndex)
    }

    private func turnContextSnapshot(from state: GameState) -> TurnContext? {
        guard state.status == .playing else { return nil }
        guard state.players.indices.contains(state.currentPlayerIndex) else { return nil }
        return TurnContext(state: state, playerIndex: state.currentPlayerIndex)
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
        scoredPlayOptions(forPlayerAt: index).first.map { option in
            (option.origin, option.card, option.pileIndex)
        }
    }

    private func bestDiscard(forPlayerAt index: Int) -> (handIndex: Int, discardIndex: Int, card: Card)? {
        guard state.players.indices.contains(index) else { return nil }
        let player = state.players[index]
        guard !player.hand.isEmpty else { return nil }
        let context = context(for: index)
        var bestOption: DiscardOption?
        for (handIndex, card) in player.hand.enumerated() {
            guard let option = evaluateDiscard(card: card, handIndex: handIndex, player: player, playerIndex: index, context: context) else { continue }
            if let current = bestOption {
                if option.score > current.score {
                    bestOption = option
                }
            } else {
                bestOption = option
            }
        }
        guard let bestOption else { return nil }
        return (bestOption.handIndex, bestOption.discardIndex, bestOption.card)
    }

    private func scoredPlayOptions(forPlayerAt index: Int) -> [PlayOption] {
        guard state.players.indices.contains(index) else { return [] }
        let context = context(for: index)
        let candidates = playCandidates(in: state, for: index)
        var scored: [PlayOption] = []
        for candidate in candidates {
            if let option = evaluate(candidate: candidate, for: index, context: context) {
                scored.append(option)
            }
        }
        return scored.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                if lhs.origin.priorityValue == rhs.origin.priorityValue {
                    if lhs.pileIndex == rhs.pileIndex {
                        return lhs.card.id.uuidString < rhs.card.id.uuidString
                    }
                    return lhs.pileIndex < rhs.pileIndex
                }
                return lhs.origin.priorityValue < rhs.origin.priorityValue
            }
            return lhs.score > rhs.score
        }
    }

    private func context(for playerIndex: Int) -> TurnContext {
        if let context = turnContext,
           context.playerIndex == playerIndex,
           context.turnIdentifier == state.turnIdentifier {
            return context
        }
        return TurnContext(state: state, playerIndex: playerIndex)
    }

    private func playCandidates(in state: GameState, for playerIndex: Int) -> [PlayCandidate] {
        guard state.players.indices.contains(playerIndex) else { return [] }
        let player = state.players[playerIndex]
        var options: [PlayCandidate] = []
        if let stockCard = player.stockTopCard {
            for pileIndex in playablePiles(for: stockCard, in: state) {
                options.append(PlayCandidate(origin: .stock(playerIndex: playerIndex), card: stockCard, pileIndex: pileIndex))
            }
        }
        for (handIndex, card) in player.hand.enumerated() {
            for pileIndex in playablePiles(for: card, in: state) {
                options.append(PlayCandidate(origin: .hand(playerIndex: playerIndex, handIndex: handIndex), card: card, pileIndex: pileIndex))
            }
        }
        for (discardIndex, pile) in player.discardPiles.enumerated() {
            guard let card = pile.last else { continue }
            for pileIndex in playablePiles(for: card, in: state) {
                options.append(PlayCandidate(origin: .discard(playerIndex: playerIndex, pileIndex: discardIndex, depth: 0), card: card, pileIndex: pileIndex))
            }
        }
        return options
    }

    private func discardPlayCandidates(in state: GameState, for playerIndex: Int) -> [PlayCandidate] {
        guard state.players.indices.contains(playerIndex) else { return [] }
        let player = state.players[playerIndex]
        var options: [PlayCandidate] = []
        for (discardIndex, pile) in player.discardPiles.enumerated() {
            guard let card = pile.last else { continue }
            for pileIndex in playablePiles(for: card, in: state) {
                options.append(PlayCandidate(origin: .discard(playerIndex: playerIndex, pileIndex: discardIndex, depth: 0), card: card, pileIndex: pileIndex))
            }
        }
        return options
    }

    private func playablePiles(for card: Card, in state: GameState) -> [Int] {
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

    private func evaluate(candidate: PlayCandidate, for playerIndex: Int, context: TurnContext) -> PlayOption? {
        var simulationState = state
        simulationState.currentPlayerIndex = playerIndex
        simulationState.phase = .acting
        guard let playResult = try? engine.play(origin: candidate.origin, toBuildPile: candidate.pileIndex, state: &simulationState) else {
            return nil
        }

        if playResult.didEmptyStock {
            return PlayOption(
                origin: candidate.origin,
                card: candidate.card,
                pileIndex: candidate.pileIndex,
                score: 1_000,
                continuation: ContinuationSummary(maxTotalPlays: 1, canReachStock: true, handCycleAchieved: candidate.origin.isHand, maxHandCardsPlayed: candidate.origin.isHand ? 1 : 0),
                risk: OpponentRisk(unlocksStock: false),
                triggeredHandCycle: false
            )
        }

        let triggeredHandCycle = candidate.origin.isHand && simulationState.players[playerIndex].hand.count > state.players[playerIndex].hand.count
        let continuation = exploreContinuations(
            in: simulationState,
            playerIndex: playerIndex,
            depthRemaining: continuationDepthLimit - 1,
            playsSoFar: 1,
            handCardsPlayed: candidate.origin.isHand ? 1 : 0,
            stockPlayed: candidate.origin.isStock,
            handCycleAchieved: triggeredHandCycle
        )
        let risk = opponentRisk(after: simulationState, actingPlayerIndex: playerIndex)
        let score = score(
            for: candidate,
            playResult: playResult,
            continuation: continuation,
            risk: risk,
            context: context,
            triggeredHandCycle: triggeredHandCycle
        )
        return PlayOption(origin: candidate.origin, card: candidate.card, pileIndex: candidate.pileIndex, score: score, continuation: continuation, risk: risk, triggeredHandCycle: triggeredHandCycle)
    }

    private func exploreContinuations(
        in state: GameState,
        playerIndex: Int,
        depthRemaining: Int,
        playsSoFar: Int,
        handCardsPlayed: Int,
        stockPlayed: Bool,
        handCycleAchieved: Bool
    ) -> ContinuationSummary {
        var best = ContinuationSummary(
            maxTotalPlays: playsSoFar,
            canReachStock: stockPlayed,
            handCycleAchieved: handCycleAchieved,
            maxHandCardsPlayed: handCardsPlayed
        )

        guard depthRemaining > 0, state.status == .playing else {
            return best
        }

        let options = playCandidates(in: state, for: playerIndex)
        guard !options.isEmpty else { return best }

        for option in options {
            var nextState = state
            nextState.currentPlayerIndex = playerIndex
            nextState.phase = .acting
            guard let _ = try? engine.play(origin: option.origin, toBuildPile: option.pileIndex, state: &nextState) else { continue }
            let priorHandCount = state.players[playerIndex].hand.count
            let nextHandCount = nextState.players[playerIndex].hand.count
            let triggeredCycle = option.origin.isHand && nextHandCount > priorHandCount
            let nextSummary = exploreContinuations(
                in: nextState,
                playerIndex: playerIndex,
                depthRemaining: depthRemaining - 1,
                playsSoFar: playsSoFar + 1,
                handCardsPlayed: handCardsPlayed + (option.origin.isHand ? 1 : 0),
                stockPlayed: stockPlayed || option.origin.isStock,
                handCycleAchieved: handCycleAchieved || triggeredCycle
            )
            best = best.combining(with: nextSummary)
        }

        return best
    }

    private func opponentRisk(after state: GameState, actingPlayerIndex: Int) -> OpponentRisk {
        guard state.players.count > 1 else { return OpponentRisk(unlocksStock: false) }
        guard let opponentIndex = nextOpponentIndex(from: actingPlayerIndex, in: state) else { return OpponentRisk(unlocksStock: false) }
        let unlocks = opponentCanReachStockUsingDiscards(in: state, playerIndex: opponentIndex, depth: opponentContinuationDepth)
        return OpponentRisk(unlocksStock: unlocks)
    }

    private func nextOpponentIndex(from index: Int, in state: GameState) -> Int? {
        guard state.players.count > 1 else { return nil }
        let opponent = (index + 1) % state.players.count
        guard state.players.indices.contains(opponent) else { return nil }
        return opponent
    }

    private func opponentCanReachStockUsingDiscards(in state: GameState, playerIndex: Int, depth: Int) -> Bool {
        guard depth >= 0 else { return false }
        guard state.players.indices.contains(playerIndex) else { return false }
        guard let stockCard = state.players[playerIndex].stockTopCard else { return false }

        var workingState = state
        workingState.currentPlayerIndex = playerIndex
        workingState.phase = .acting

        if !playablePiles(for: stockCard, in: workingState).isEmpty {
            return true
        }
        guard depth > 0 else { return false }

        for option in discardPlayCandidates(in: workingState, for: playerIndex) {
            var nextState = workingState
            guard let _ = try? engine.play(origin: option.origin, toBuildPile: option.pileIndex, state: &nextState) else { continue }
            if opponentCanReachStockUsingDiscards(in: nextState, playerIndex: playerIndex, depth: depth - 1) {
                return true
            }
        }
        return false
    }

    private func score(
        for candidate: PlayCandidate,
        playResult: PlayResult,
        continuation: ContinuationSummary,
        risk: OpponentRisk,
        context: TurnContext,
        triggeredHandCycle: Bool
    ) -> Double {
        var score: Double = 0

        switch candidate.origin {
        case .stock:
            score += 200
        case .hand:
            score += 30
        case .discard:
            score += 40
        }

        if playResult.didCompleteBuild {
            score += 12
        }
        if playResult.didEmptyStock {
            score += 1_000
        }

        if let lastPlay = context.lastPlay, lastPlay.pileIndex == candidate.pileIndex {
            score += 15
        } else if context.playsThisTurn > 0 {
            score += 5
        }

        score += Double(continuation.maxTotalPlays) * 6
        score += Double(continuation.maxHandCardsPlayed) * 3

        if continuation.canReachStock {
            score += 80
        }
        if continuation.handCycleAchieved {
            score += 25
            if continuation.canReachStock {
                score += 20
            }
        }
        if triggeredHandCycle {
            score += 18
        }

        if candidate.card.isWild {
            if continuation.canReachStock {
                score += 30
            } else {
                score -= 40
            }
        }

        if risk.unlocksStock {
            if continuation.canReachStock {
                score -= 15
            } else {
                score -= 85
            }
        }

        if !continuation.canReachStock && !candidate.origin.isStock {
            score -= Double(context.handCardsPlayed) * 2
        }

        return score
    }

    private func evaluateDiscard(
        card: Card,
        handIndex: Int,
        player: Player,
        playerIndex: Int,
        context: TurnContext
    ) -> DiscardOption? {
        var bestOption: DiscardOption?
        for (discardIndex, pile) in player.discardPiles.enumerated() {
            let score = discardScore(for: card, into: pile, discardIndex: discardIndex, player: player, context: context)
            let option = DiscardOption(handIndex: handIndex, discardIndex: discardIndex, card: card, score: score)
            if let current = bestOption {
                if option.score > current.score {
                    bestOption = option
                }
            } else {
                bestOption = option
            }
        }
        return bestOption
    }

    private func discardScore(
        for card: Card,
        into pile: [Card],
        discardIndex: Int,
        player: Player,
        context: TurnContext
    ) -> Double {
        let cardValue = card.value.rawValue
        var score = Double(cardValue) * 1.2

        if card.isWild {
            score -= 90
        }

        if !playablePiles(for: card, in: state).isEmpty {
            score -= 35
        }

        if let stockCard = player.stockTopCard {
            if card.isWild {
                score -= 25
            } else if card.value == stockCard.value {
                score -= 45
            } else if card.value.nextValue == stockCard.value {
                score -= 20
            }
        }

        if let top = pile.last {
            let topValue = top.value.rawValue
            if topValue > cardValue {
                score += 20
                score += Double(max(0, 6 - abs(topValue - cardValue))) * 2
                if topValue == cardValue + 1 {
                    score += 14
                }
            } else if topValue == cardValue {
                score -= 6
            } else {
                score -= Double((cardValue - topValue + 1) * 6)
            }
        } else {
            score += Double(cardValue) * 0.6
            if cardValue >= 11 { score += 6 }
        }

        let minCount = player.discardPiles.map(\.count).min() ?? 0
        if pile.count == minCount {
            score += 3
        } else if pile.count > minCount {
            score -= Double(pile.count - minCount)
        }

        if let lastDiscard = context.discards.last, lastDiscard.discardIndex == discardIndex {
            score += 4
        }

        return score
    }

    private struct PlayOption {
        let origin: CardOrigin
        let card: Card
        let pileIndex: Int
        let score: Double
        let continuation: ContinuationSummary
        let risk: OpponentRisk
        let triggeredHandCycle: Bool
    }

    private struct PlayCandidate {
        let origin: CardOrigin
        let card: Card
        let pileIndex: Int
    }

    private struct ContinuationSummary {
        var maxTotalPlays: Int
        var canReachStock: Bool
        var handCycleAchieved: Bool
        var maxHandCardsPlayed: Int

        func combining(with other: ContinuationSummary) -> ContinuationSummary {
            ContinuationSummary(
                maxTotalPlays: max(maxTotalPlays, other.maxTotalPlays),
                canReachStock: canReachStock || other.canReachStock,
                handCycleAchieved: handCycleAchieved || other.handCycleAchieved,
                maxHandCardsPlayed: max(maxHandCardsPlayed, other.maxHandCardsPlayed)
            )
        }
    }

    private struct OpponentRisk {
        let unlocksStock: Bool
    }

    private struct DiscardOption {
        let handIndex: Int
        let discardIndex: Int
        let card: Card
        let score: Double
    }

    private struct TurnContext {
        struct PlayRecord {
            let origin: CardOrigin
            let card: Card
            let pileIndex: Int
        }

        struct DiscardRecord {
            let card: Card
            let handIndex: Int
            let discardIndex: Int
        }

        let turnIdentifier: Int
        let playerIndex: Int
        let startingHandCount: Int
        let startingDiscardTops: [Card?]
        let startingStockTop: Card?
        let startingBuildTargets: [CardValue]
        private(set) var plays: [PlayRecord]
        private(set) var discards: [DiscardRecord]

        init(state: GameState, playerIndex: Int) {
            self.turnIdentifier = state.turnIdentifier
            self.playerIndex = playerIndex
            self.startingHandCount = state.players[playerIndex].hand.count
            self.startingDiscardTops = state.players[playerIndex].discardPiles.map { $0.last }
            self.startingStockTop = state.players[playerIndex].stockTopCard
            self.startingBuildTargets = state.buildPiles.map(\.nextRequiredValue)
            self.plays = []
            self.discards = []
        }

        var playsThisTurn: Int { plays.count }
        var handCardsPlayed: Int { plays.filter { $0.origin.isHand }.count }
        var stockCardsPlayed: Int { plays.filter { $0.origin.isStock }.count }
        var hasPlayedStock: Bool { stockCardsPlayed > 0 }
        var lastPlay: PlayRecord? { plays.last }

        mutating func notePlay(origin: CardOrigin, card: Card, pileIndex: Int) {
            plays.append(PlayRecord(origin: origin, card: card, pileIndex: pileIndex))
        }

        mutating func noteDiscard(card: Card, handIndex: Int, discardIndex: Int) {
            discards.append(DiscardRecord(card: card, handIndex: handIndex, discardIndex: discardIndex))
        }
    }
}

private extension CardOrigin {
    var isStock: Bool {
        if case .stock = self { return true }
        return false
    }

    var isHand: Bool {
        if case .hand = self { return true }
        return false
    }

    var isDiscard: Bool {
        if case .discard = self { return true }
        return false
    }

    var priorityValue: Int {
        switch self {
        case .stock:
            return 0
        case .hand:
            return 1
        case .discard:
            return 2
        }
    }
}
#endif

