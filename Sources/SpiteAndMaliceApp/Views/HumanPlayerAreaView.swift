#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct HumanPlayerAreaView: View {
    var player: Player
    var playerIndex: Int
    var isCurrentTurn: Bool
    var selection: GameViewModel.CardSelection?
    var onSelectStock: () -> Void
    var onTapDiscard: (Int) -> Void
    var onSelectHandCard: (Int) -> Void

    private var selectedDiscardIndex: Int? {
        guard let selection else { return nil }
        if case let .discard(_, index, _) = selection.origin { return index }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PlayerHeaderView(player: player, isCurrentTurn: isCurrentTurn)
            HStack(alignment: .top, spacing: 18) {
                StockPileView(
                    card: player.stockTopCard,
                    remainingCount: player.stockPile.count,
                    isFaceDown: false,
                    isHighlighted: selection?.origin.playerIndex == playerIndex && (selection?.origin.isStock ?? false),
                    action: onSelectStock
                )

                HStack(spacing: 14) {
                    ForEach(Array(player.discardPiles.indices), id: \.self) { index in
                        DiscardPileView(
                            cards: player.discardPiles[index],
                            title: "Discard \(index + 1)",
                            isHighlighted: selectedDiscardIndex == index,
                            isInteractive: true,
                            action: { onTapDiscard(index) }
                        )
                    }
                }
                Spacer()
            }

            HandView(
                cards: player.hand,
                selectedCardID: selection?.card.id,
                tapAction: onSelectHandCard
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private extension CardOrigin {
    var isStock: Bool {
        if case .stock = self { return true }
        return false
    }
}
#endif
