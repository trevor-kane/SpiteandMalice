#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct OpponentAreaView: View {
    var player: Player
    var isCurrentTurn: Bool

    var body: some View {
        VStack(spacing: 18) {
            PlayerHeaderView(player: player, isCurrentTurn: isCurrentTurn)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .top, spacing: 26) {
                StockPileView(
                    cards: player.stockPile,
                    isFaceDown: false,
                    isHighlighted: isCurrentTurn,
                    action: nil
                )

                HStack(spacing: 18) {
                    ForEach(Array(player.discardPiles.indices), id: \.self) { index in
                        let pile = player.discardPiles[index]
                        DiscardPileView(
                            cards: pile,
                            title: "Discard",
                            isHighlighted: isCurrentTurn && !pile.isEmpty,
                            isInteractive: false,
                            action: nil
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 8) {
                Text("\(player.name)'s Hand")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.78))

                OpponentHandSummaryView(count: player.hand.count)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct OpponentHandSummaryView: View {
    var count: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.23, green: 0.27, blue: 0.39), Color(red: 0.15, green: 0.18, blue: 0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.2)
                )
                .frame(width: 70, height: 98)

            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text(count == 1 ? "card" : "cards")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Opponent hand has \(count) cards"))
    }
}
#endif
