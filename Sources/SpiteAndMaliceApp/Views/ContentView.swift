#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct ContentView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        ZStack(alignment: .top) {
            backgroundView
            VStack(alignment: .leading, spacing: 24) {
                header
                opponentsSection
                centrePlayArea
                humanSection
                controlSection
                footerSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if let hint = viewModel.hint?.message {
                VStack {
                    HintOverlayView(message: hint)
                    Spacer()
                }
                .padding(.top, 16)
                .transition(.opacity)
            }
        }
        .frame(minWidth: 960, minHeight: 720)
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
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(viewModel.statusBanner)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .textCase(nil)
        }
    }

    private var opponentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(viewModel.state.players.enumerated()).filter { !$0.element.isHuman }, id: \.element.id) { item in
                OpponentAreaView(
                    player: item.element,
                    isCurrentTurn: viewModel.state.currentPlayerIndex == item.offset
                )
            }
        }
    }

    private var centrePlayArea: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ForEach(Array(viewModel.state.buildPiles.enumerated()), id: \.0) { index, pile in
                    BuildPileView(
                        pile: pile,
                        title: viewModel.buildPileTitle(for: index),
                        isActiveTarget: viewModel.isValidTarget(for: index),
                        action: viewModel.state.currentPlayer.isHuman ? { viewModel.playSelectedCard(on: index) } : nil
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
    }

    private var humanSection: some View {
        if let humanIndex = viewModel.state.players.firstIndex(where: { $0.isHuman }) {
            let player = viewModel.state.players[humanIndex]
            return AnyView(
                HumanPlayerAreaView(
                    player: player,
                    playerIndex: humanIndex,
                    isCurrentTurn: viewModel.state.currentPlayerIndex == humanIndex,
                    selection: viewModel.selection,
                    onSelectStock: viewModel.selectStockCard,
                    onTapDiscard: { index in viewModel.handleDiscardTap(index) },
                    onSelectHandCard: { index in viewModel.selectHandCard(at: index) }
                )
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    private var controlSection: some View {
        ControlPanelView(
            onNewGame: viewModel.startNewGame,
            onHint: viewModel.provideHint,
            onEndTurn: viewModel.endTurnIfPossible,
            isHintDisabled: !viewModel.state.currentPlayer.isHuman || viewModel.state.status != .playing,
            isEndTurnDisabled: !(viewModel.state.currentPlayer.isHuman && viewModel.state.phase == .waiting),
            showsHelp: $viewModel.showsHelp
        )
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent activity")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            ForEach(viewModel.activityLog()) { event in
                Text(event.message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }

    private var helpPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to play")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text("Play cards from your stock, hand or discard piles to the shared build piles in ascending order from Ace to Queen. Kings are wild and take on any needed value. End your turn by discarding a card from your hand.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}
#endif
