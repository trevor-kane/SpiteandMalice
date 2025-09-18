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
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                countIndicator
                    .accessibilityHidden(true)

                stockContent
                    .accessibilityLabel(Text(accessibilityLabel))
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Text("Stock")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    @ViewBuilder
    private var stockContent: some View {
        if let card = topCard {
            interactiveCard(for: card)
                .frame(height: 98)
        } else {
            placeholderCard
                .frame(height: 98)
        }
    }

    @ViewBuilder
    private func interactiveCard(for card: Card) -> some View {
        let view = CardView(card: card, isFaceDown: isFaceDown, isHighlighted: isHighlighted, showsGlow: isHighlighted)
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

    private var countIndicator: some View {
        VStack(spacing: 4) {
            Text("Remaining")
                .font(.system(size: 11, weight: .medium, design: .rounded))
            Text("\(remainingCount)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 8, y: 6)
        .opacity(remainingCount == 0 ? 0.6 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Stock cards remaining: \(remainingCount)"))
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
