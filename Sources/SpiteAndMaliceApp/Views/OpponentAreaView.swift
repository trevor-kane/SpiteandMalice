#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct OpponentAreaView: View {
    var player: Player
    var isCurrentTurn: Bool
    var showsContainer: Bool = true

    var body: some View {
        let content = VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                PlayerHeaderView(player: player, isCurrentTurn: isCurrentTurn)
                    .frame(maxWidth: .infinity, alignment: .leading)

                OpponentHandSummaryView(count: player.hand.count)
            }

            HStack(alignment: .top, spacing: 22) {
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
        }

        Group {
            if showsContainer {
                content
                    .padding(.vertical, 18)
                    .padding(.horizontal, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                content
            }
        }
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
                .frame(width: 64, height: 94)

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
