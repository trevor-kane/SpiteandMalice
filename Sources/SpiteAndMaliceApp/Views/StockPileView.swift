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
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 16) {
                countIndicator
                stockContent
                    .accessibilityLabel(Text(accessibilityLabel))
            }

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

    private var countIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 16, weight: .semibold))
            Text("\(remainingCount)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text("Left")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .opacity(0.8)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.26), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.95)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 0.9)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
        .frame(minWidth: 68)
        .opacity(remainingCount == 0 ? 0.65 : 1)
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
