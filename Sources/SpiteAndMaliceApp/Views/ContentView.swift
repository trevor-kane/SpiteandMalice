#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct ContentView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        let summary = viewModel.gameSummary
        ZStack(alignment: .top) {
            backgroundView
            ScrollView(.vertical, showsIndicators: true) {
                mainContent
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity)
            }
            .blur(radius: summary == nil ? 0 : 8)
            .allowsHitTesting(summary == nil)

            if let summary {
                WinOverlayView(summary: summary, onPlayAgain: { viewModel.startNewGame() })
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: summary != nil)
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 32) {
                activityColumn

                VStack(spacing: 28) {
                    opponentsSection
                    centrePlayArea
                    humanSection
                    controlSection
                }
                .frame(maxWidth: .infinity, alignment: .center)

                sidebarColumn
            }
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 32)
        .frame(maxWidth: 1360)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var activityColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            RecentActivityView(events: viewModel.activityLog())
            Spacer(minLength: 0)
        }
        .frame(width: 260, alignment: .leading)
    }

    private var sidebarColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScoreboardView(
                players: viewModel.state.players,
                currentPlayerIndex: viewModel.state.currentPlayerIndex,
                turn: viewModel.state.turn
            )

            if let hint = viewModel.hint, viewModel.gameSummary == nil {
                HintOverlayView(message: hint.message, recommendations: hint.recommendations)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .frame(width: 280, alignment: .leading)
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
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(viewModel.state.players.enumerated()).filter { !$0.element.isHuman }, id: \.element.id) { item in
                OpponentAreaView(
                    player: item.element,
                    isCurrentTurn: viewModel.state.currentPlayerIndex == item.offset
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var centrePlayArea: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 28) {
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
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
                onSelectHandCard: { index in viewModel.selectHandCard(at: index) }
            )
        }
    }

    private var controlSection: some View {
        ControlPanelView(
            onNewGame: { viewModel.startNewGame() },
            onHint: viewModel.provideHint,
            onUndo: viewModel.undoLastAction,
            isHintDisabled: !viewModel.state.currentPlayer.isHuman || viewModel.state.status != .playing,
            isHintPinned: viewModel.isHintPinned,
            isUndoDisabled: !viewModel.canUndoTurn
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
#endif



