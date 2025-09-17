#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct ScoreboardView: View {
    var players: [Player]
    var currentPlayerIndex: Int
    var turn: Int

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 240), spacing: 16)] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Scoreboard")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("Turn \(turn)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    ScoreboardPlayerCard(
                        player: player,
                        isCurrent: index == currentPlayerIndex
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct ScoreboardPlayerCard: View {
    var player: Player
    var isCurrent: Bool

    private var discardCount: Int { player.discardPiles.reduce(0) { $0 + $1.count } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Text(player.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                if player.isHuman {
                    Text("You")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue.opacity(0.45)))
                }
                Spacer()
                if isCurrent {
                    Label("Active", systemImage: "flame.fill")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.yellow.opacity(0.45)))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                statRow(icon: "rectangle.stack.fill", label: "Stock", value: "\(player.stockPile.count)")
                statRow(icon: "hand.tap.fill", label: "Hand", value: "\(player.hand.count)")
                statRow(icon: "tray.full.fill", label: "Discard", value: "\(discardCount)")
                statRow(icon: "checkmark.seal.fill", label: "Stock cleared", value: "\(player.completedStockCards)")
                statRow(icon: "arrow.up.circle.fill", label: "Cards played", value: "\(player.cardsPlayed)")
                statRow(icon: "arrow.down.circle.fill", label: "Cards discarded", value: "\(player.cardsDiscarded)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isCurrent ? Color.yellow.opacity(0.45) : Color.white.opacity(0.08), lineWidth: isCurrent ? 2 : 1)
                )
        )
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 18)
                .foregroundColor(.white.opacity(0.75))
            Text(label)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.72))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
        }
    }
}
#endif
