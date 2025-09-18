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

                PlayerHandSummaryView(
                    title: "Hand",
                    count: player.hand.count,
                    gradientColors: [
                        Color(red: 0.62, green: 0.41, blue: 0.86).opacity(0.95),
                        Color(red: 0.43, green: 0.25, blue: 0.66).opacity(0.95)
                    ],
                    borderColor: Color.white.opacity(0.26),
                    titleColor: Color.white.opacity(0.8),
                    countColor: .white
                )
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
                            .fill(Color.purple.opacity(0.16))
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                content
            }
        }
    }
}
#endif
