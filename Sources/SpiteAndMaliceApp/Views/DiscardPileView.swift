#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct DiscardPileView: View {
    var cards: [Card]
    var title: String
    var isHighlighted: Bool = false
    var isInteractive: Bool = false
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 6) {
            discardContent
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
        }
        .opacity(isInteractive ? 1 : 0.9)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: cards.count)
    }

    @ViewBuilder
    private var discardContent: some View {
        ZStack(alignment: .topLeading) {
            if cards.count > 1 {
                PeekingCardStack(
                    cards: Array(cards.dropLast()),
                    isFaceDown: false,
                    scale: 0.92
                )
            }

            if let card = cards.last {
                interactiveTopCard(card: card)
                    .offset(y: PeekingCardStack.topCardOffset(forTotalCount: cards.count))
            } else {
                placeholderCard
            }
        }
        .frame(height: PeekingCardStack.totalStackHeight(forTotalCount: cards.count, topScale: 0.95))
    }

    @ViewBuilder
    private func interactiveTopCard(card: Card) -> some View {
        let view = CardView(card: card, isHighlighted: isHighlighted, showsGlow: isHighlighted, scale: 0.95)
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
                CardPlaceholder(title: "Discard")
                    .scaleEffect(0.95)
            }
            .buttonStyle(.plain)
            .opacity(isInteractive ? 1 : 0.65)
        } else {
            CardPlaceholder(title: "Discard")
                .scaleEffect(0.95)
                .opacity(isInteractive ? 1 : 0.65)
        }
    }
}
#endif
