#if canImport(SwiftUI)
import SwiftUI

struct WinOverlayView: View {
    let summary: GameViewModel.GameSummary
    var onPlayAgain: () -> Void

    private var titleText: String {
        summary.winner.isHuman ? "You Win!" : "\(summary.winner.name) Wins"
    }

    private var subtitleText: String {
        let turnWord = summary.totalTurns == 1 ? "turn" : "turns"
        let buildWord = summary.buildPilesCompleted == 1 ? "build pile" : "build piles"
        return "Game finished in \(summary.totalTurns) \(turnWord) with \(summary.buildPilesCompleted) completed \(buildWord)."
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text(titleText)
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(subtitleText)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                playerStats

                Button(action: onPlayAgain) {
                    Label("Play Again", systemImage: "arrow.clockwise.circle.fill")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.white.opacity(0.2))
                .foregroundStyle(.white)
            }
            .padding(40)
            .frame(maxWidth: 620)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
            .padding(.horizontal, 24)
        }
    }

    private var playerStats: some View {
        VStack(spacing: 18) {
            ForEach(summary.players) { player in
                playerCard(for: player)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func playerCard(for player: GameViewModel.PlayerSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(player.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                if player.isWinner {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
                Spacer()
                Text(player.isHuman ? "You" : "Opponent")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

            Divider()
                .overlay(Color.white.opacity(0.25))

            statRow(icon: "rectangle.stack.fill", label: "Stock remaining", value: "\(player.stockRemaining)")
            statRow(icon: "checkmark.circle.fill", label: "Stock cards cleared", value: "\(player.completedStockCards)")
            statRow(icon: "suit.club.fill", label: "Cards played", value: "\(player.cardsPlayed)")
            statRow(icon: "arrow.down.circle.fill", label: "Cards discarded", value: "\(player.cardsDiscarded)")
            statRow(icon: "hand.draw.fill", label: "Hand cards", value: "\(player.handCount)")
            statRow(icon: "tray.full.fill", label: "Discard pile cards", value: "\(player.discardCardCount)")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(player.isWinner ? 0.18 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(player.isWinner ? 0.4 : 0.25), lineWidth: 1)
        )
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.78))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
#endif
