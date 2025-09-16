#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct OpponentAreaView: View {
    var player: Player
    var isCurrentTurn: Bool
    var revealedDiscardIndices: Set<Int>
    var onToggleDiscardReveal: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlayerHeaderView(player: player, isCurrentTurn: isCurrentTurn)
            HStack(spacing: 18) {
                StockPileView(
                    cards: player.stockPile,
                    isFaceDown: false,
                    isHighlighted: isCurrentTurn,
                    action: nil
                )

                HStack(spacing: 14) {
                    ForEach(Array(player.discardPiles.indices), id: \.self) { index in
                        let pile = player.discardPiles[index]
                        DiscardPileView(
                            cards: pile,
                            title: "Discard \(index + 1)",
                            isHighlighted: isCurrentTurn && !pile.isEmpty,
                            isInteractive: false,
                            action: nil,
                            isRevealed: revealedDiscardIndices.contains(index),
                            onRevealToggle: { onToggleDiscardReveal(index) }
                        )
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
