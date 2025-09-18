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
        VStack(spacing: 20) {
            PlayerHeaderView(player: player, isCurrentTurn: isCurrentTurn)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .top, spacing: 26) {
                StockPileView(
                    cards: player.stockPile,
                    isFaceDown: false,
                    isHighlighted: selection?.origin.playerIndex == playerIndex && (selection?.origin.isStock ?? false),
                    action: onSelectStock
                )

                HStack(spacing: 18) {
                    ForEach(Array(player.discardPiles.indices), id: \.self) { index in
                        DiscardPileView(
                            cards: player.discardPiles[index],
                            title: "Discard",
                            isHighlighted: selectedDiscardIndex == index,
                            isInteractive: true,
                            action: { onTapDiscard(index) }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 8) {
                Text("Your Hand")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                HandView(
                    cards: player.hand,
                    selectedCardID: selection?.card.id,
                    tapAction: onSelectHandCard
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private extension CardOrigin {
    var isStock: Bool {
        if case .stock = self { return true }
        return false
    }
}
#endif
