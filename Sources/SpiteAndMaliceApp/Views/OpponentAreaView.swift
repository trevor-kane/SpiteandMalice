#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct OpponentAreaView: View {
    var player: Player
    var isCurrentTurn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlayerHeaderView(player: player, isCurrentTurn: isCurrentTurn)
            HStack(spacing: 18) {
                StockPileView(
                    card: player.stockTopCard,
                    remainingCount: player.stockPile.count,
                    isFaceDown: true,
                    isHighlighted: isCurrentTurn
                )
                .allowsHitTesting(false)

                HStack(spacing: 14) {
                    ForEach(Array(player.discardPiles.indices), id: \.self) { index in
                        let pile = player.discardPiles[index]
                        DiscardPileView(
                            cards: pile,
                            title: "Discard \(index + 1)",
                            isHighlighted: isCurrentTurn && !pile.isEmpty,
                            isInteractive: false,
                            action: nil
                        )
                        .allowsHitTesting(false)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}
#endif
