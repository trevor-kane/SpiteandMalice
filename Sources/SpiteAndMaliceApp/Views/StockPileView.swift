#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct StockPileView: View {
    var cards: [Card]
    var isFaceDown: Bool
    var isHighlighted: Bool = false
    var action: (() -> Void)?

    private var remainingCount: Int { cards.count }
    private var topCard: Card? { cards.last }

    var body: some View {
        VStack(spacing: 6) {
            stockContent
                .overlay(alignment: .topTrailing) {
                    if remainingCount > 0 {
                        countBadge
                    }
                }
                .accessibilityLabel(Text(accessibilityLabel))

            Text("Stock")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    @ViewBuilder
    private var stockContent: some View {
        if let card = topCard {
            interactiveCard(for: card)
        } else {
            placeholderCard
        }
    }

    @ViewBuilder
    private func interactiveCard(for card: Card) -> some View {
        let view = CardView(card: card, isFaceDown: isFaceDown, isHighlighted: isHighlighted, showsGlow: isHighlighted, scale: 1.05)
        if let action {
            Button(action: action) {
                view
            }
            .buttonStyle(.plain)
        } else {
            view
        }
    }

    @ViewBuilder
    private var placeholderCard: some View {
        if let action {
            Button(action: action) {
                CardPlaceholder(title: "Stock")
            }
            .buttonStyle(.plain)
        } else {
            CardPlaceholder(title: "Stock")
        }
    }

    private var countBadge: some View {
        Text("\(remainingCount)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(6)
            .background(Circle().fill(Color.black.opacity(0.45)))
            .offset(x: 26, y: -32)
    }

    private var accessibilityLabel: String {
        if let card = topCard, !isFaceDown {
            return "Stock pile showing \(card.value.accessibilityLabel) with \(remainingCount) cards remaining."
        } else {
            return "Stock pile with \(remainingCount) cards remaining."
        }
    }
}
#endif
