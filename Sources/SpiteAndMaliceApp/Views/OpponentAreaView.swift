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
#endif
