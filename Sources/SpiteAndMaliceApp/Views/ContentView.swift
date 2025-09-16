#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

private struct DiscardIdentifier: Hashable {
    let playerID: UUID
    let pileIndex: Int
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: GameViewModel
    @State private var revealedBuildPileIDs: Set<UUID> = []
    @State private var revealedStockPlayerIDs: Set<UUID> = []
    @State private var revealedDiscardIdentifiers: Set<DiscardIdentifier> = []

    var body: some View {
        let summary = viewModel.gameSummary
        ZStack(alignment: .top) {
            backgroundView
            mainContent
                .blur(radius: summary == nil ? 0 : 8)
                .allowsHitTesting(summary == nil)

            if let hint = viewModel.hint?.message, summary == nil {
                VStack {
                    HintOverlayView(message: hint)
                    Spacer()
                }
                .padding(.top, 24)
                .transition(.opacity)
            }

            if let summary {
                WinOverlayView(summary: summary, onPlayAgain: viewModel.startNewGame)
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(minWidth: 1180, minHeight: 820)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: summary != nil)
    }

    private var mainContent: some View {
        VStack(spacing: 28) {
            header
                .frame(maxWidth: .infinity, alignment: .leading)

            opponentsSection
            centrePlayArea
            humanSection
            controlSection
            footerSection
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 42)
        .padding(.horizontal, 36)
        .frame(maxWidth: 1320)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 0.07, green: 0.11, blue: 0.2), Color(red: 0.16, green: 0.2, blue: 0.36)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Spite & Malice")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(viewModel.statusBanner)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .textCase(nil)
        }
    }

    private var opponentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(viewModel.state.players.enumerated()).filter { !$0.element.isHuman }, id: \.element.id) { item in
                OpponentAreaView(
                    player: item.element,
                    isCurrentTurn: viewModel.state.currentPlayerIndex == item.offset,
                    isStockRevealed: revealedStockPlayerIDs.contains(item.element.id),
                    onToggleStockReveal: { toggleStockReveal(for: item.element.id) },
                    revealedDiscardIndices: revealedDiscardIndices(for: item.element.id),
                    onToggleDiscardReveal: { index in toggleDiscardReveal(for: item.element.id, pileIndex: index) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var centrePlayArea: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                ForEach(Array(viewModel.state.buildPiles.enumerated()), id: \.0) { index, pile in
                    BuildPileView(
                        pile: pile,
                        title: viewModel.buildPileTitle(for: index),
                        isActiveTarget: viewModel.isValidTarget(for: index),
                        action: viewModel.state.currentPlayer.isHuman ? { viewModel.playSelectedCard(on: index) } : nil,
                        isRevealed: revealedBuildPileIDs.contains(pile.id),
                        onRevealToggle: { toggleBuildReveal(id: pile.id) }
                    )
                    .disabled(!viewModel.state.currentPlayer.isHuman)
                }

                DrawPileView(
                    drawCount: viewModel.state.drawPile.count,
                    recycleCount: viewModel.state.recyclePile.count
                )
            }

            if viewModel.showsHelp {
                helpPanel
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var humanSection: some View {
        if let humanIndex = viewModel.state.players.firstIndex(where: { $0.isHuman }) {
            let player = viewModel.state.players[humanIndex]
            HumanPlayerAreaView(
                player: player,
                playerIndex: humanIndex,
                isCurrentTurn: viewModel.state.currentPlayerIndex == humanIndex,
                selection: viewModel.selection,
                onSelectStock: viewModel.selectStockCard,
                onTapDiscard: { index in viewModel.handleDiscardTap(index) },
                onSelectHandCard: { index in viewModel.selectHandCard(at: index) },
                isStockRevealed: revealedStockPlayerIDs.contains(player.id),
                onToggleStockReveal: { toggleStockReveal(for: player.id) },
                revealedDiscardIndices: revealedDiscardIndices(for: player.id),
                onToggleDiscardReveal: { index in toggleDiscardReveal(for: player.id, pileIndex: index) }
            )
        }
    }

    private var controlSection: some View {
        ControlPanelView(
            onNewGame: { viewModel.startNewGame() },
            onHint: viewModel.provideHint,
            onUndo: viewModel.undoLastAction,
            onEndTurn: viewModel.endTurnIfPossible,
            isHintDisabled: !viewModel.state.currentPlayer.isHuman || viewModel.state.status != .playing,
            isUndoDisabled: !viewModel.canUndoTurn,
            isEndTurnDisabled: !(viewModel.state.currentPlayer.isHuman && viewModel.state.phase == .waiting),
            showsHelp: $viewModel.showsHelp
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent activity")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
            ForEach(viewModel.activityLog()) { event in
                Text(event.message)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.68))
            }
        }
    }

    private var helpPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to play")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Play cards from your stock, hand or discard piles to the shared build piles in ascending order from Ace to Queen. Kings are wild and take on any needed value. End your turn by discarding a card from your hand.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func toggleBuildReveal(id: UUID) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            if revealedBuildPileIDs.contains(id) {
                revealedBuildPileIDs.remove(id)
            } else {
                revealedBuildPileIDs.insert(id)
            }
        }
    }

    private func toggleStockReveal(for playerID: UUID) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            if revealedStockPlayerIDs.contains(playerID) {
                revealedStockPlayerIDs.remove(playerID)
            } else {
                revealedStockPlayerIDs.insert(playerID)
            }
        }
    }

    private func toggleDiscardReveal(for playerID: UUID, pileIndex: Int) {
        let identifier = DiscardIdentifier(playerID: playerID, pileIndex: pileIndex)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            if revealedDiscardIdentifiers.contains(identifier) {
                revealedDiscardIdentifiers.remove(identifier)
            } else {
                revealedDiscardIdentifiers.insert(identifier)
            }
        }
    }

    private func revealedDiscardIndices(for playerID: UUID) -> Set<Int> {
        Set(revealedDiscardIdentifiers.filter { $0.playerID == playerID }.map(\.pileIndex))
    }
}
#endif
