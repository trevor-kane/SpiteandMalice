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
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                stockContent
                    .accessibilityLabel(Text(accessibilityLabel))
            }
            .frame(height: PeekingCardStack.totalStackHeight(forTotalCount: remainingCount, topScale: 1, peekScale: 0.98))
            .overlay(alignment: .topTrailing) {
                countIndicator
                    .allowsHitTesting(false)
                    .padding(8)
            }

            Text("Stock")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    @ViewBuilder
    private var stockContent: some View {
        if let card = topCard {
            if remainingCount > 1 {
                PeekingCardStack(
                    cards: Array(cards.dropLast()),
                    isFaceDown: true,
                    scale: 0.98
                )
            }

            interactiveCard(for: card)
                .offset(y: PeekingCardStack.topCardOffset(forTotalCount: remainingCount, scale: 0.98))
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
        VStack(spacing: 6) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("\(remainingCount)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 0.9)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, y: 3)
        .frame(minWidth: 62)
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
