#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct PlayerHeaderView: View {
    var player: Player
    var isCurrentTurn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: player.isHuman ? "person.fill" : "cpu")
                .foregroundColor(.white.opacity(0.9))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    if isCurrentTurn {
                        Text(player.isHuman ? "Your turn" : "Thinking")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                    }
                }
                Text("Stock: \(player.stockPile.count)  •  Discards: \(player.discardPiles.filter { !$0.isEmpty }.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
        )
    }
}
#endif
