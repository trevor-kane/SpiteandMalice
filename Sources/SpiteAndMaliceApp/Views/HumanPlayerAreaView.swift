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
    var showsContainer: Bool = true

    private var selectedDiscardIndex: Int? {
        guard let selection else { return nil }
        if case let .discard(_, index, _) = selection.origin { return index }
        return nil
    }

    var body: some View {
        let content = VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                PlayerHeaderView(player: player, isCurrentTurn: isCurrentTurn)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                PlayerHandSummaryView(
                    title: "Hand",
                    count: player.hand.count,
                    gradientColors: [
                        Color(red: 0.27, green: 0.51, blue: 0.93).opacity(0.9),
                        Color(red: 0.18, green: 0.36, blue: 0.77).opacity(0.92)
                    ],
                    borderColor: Color.white.opacity(0.22),
                    titleColor: Color.white.opacity(0.75),
                    countColor: .white
                )
            }

            HStack(alignment: .top, spacing: 22) {
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

            HandView(
                cards: player.hand,
                selectedCardID: selection?.card.id,
                tapAction: onSelectHandCard
            )
            .frame(maxWidth: .infinity, alignment: .center)
        }

        Group {
            if showsContainer {
                content
                    .padding(.vertical, 20)
                    .padding(.horizontal, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.14))
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                content
            }
        }
    }
}

private extension CardOrigin {
    var isStock: Bool {
        if case .stock = self { return true }
        return false
    }
}
#endif
