#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct ScoreboardView: View {
    var players: [Player]
    var currentPlayerIndex: Int
    var turn: Int

    private var orderedPlayers: [Player] {
        players.sorted { lhs, rhs in
            if lhs.isHuman == rhs.isHuman {
                return lhs.name < rhs.name
            }
            return lhs.isHuman && !rhs.isHuman
        }
    }

    private var currentPlayerID: UUID? {
        guard players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex].id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Scoreboard")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Turn \(turn)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.18))
                    )
            }

            VStack(alignment: .leading, spacing: 18) {
                ForEach(orderedPlayers, id: \.id) { player in
                    ScoreboardPlayerCard(
                        player: player,
                        isCurrent: player.id == currentPlayerID
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.92)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ScoreboardPlayerCard: View {
    var player: Player
    var isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Text(player.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(player.isHuman ? "You" : "AI")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(player.isHuman ? Color.blue.opacity(0.45) : Color.purple.opacity(0.4))
                    )
                Spacer()
                if isCurrent {
                    Label("Active", systemImage: "flame.fill")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.yellow.opacity(0.45)))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                statRow(icon: "rectangle.stack.fill", label: "Stock", value: "\(player.stockPile.count)")
                statRow(icon: "hand.tap.fill", label: "Hand", value: "\(player.hand.count)")
                statRow(icon: "checkmark.seal.fill", label: "Stock cleared", value: "\(player.completedStockCards)")
                statRow(icon: "crown.fill", label: "Kings played", value: "\(player.kingsPlayed)")
                statRow(icon: "arrow.up.circle.fill", label: "Cards played", value: "\(player.cardsPlayed)")
                statRow(icon: "arrow.down.circle.fill", label: "Cards discarded", value: "\(player.cardsDiscarded)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isCurrent ? Color.yellow.opacity(0.45) : Color.white.opacity(0.12), lineWidth: isCurrent ? 2 : 1)
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
