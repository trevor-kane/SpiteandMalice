#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct DiscardPileView: View {
    var cards: [Card]
    var title: String
    var isHighlighted: Bool = false
    var isInteractive: Bool = false
    var showsStackWhenMultiple: Bool = true
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
            discardStack
        }
        .frame(height: stackHeight)
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

    @ViewBuilder
    private var discardStack: some View {
        if let card = cards.last {
            if showsStackWhenMultiple, cards.count > 1 {
                let underlying = Array(cards.dropLast())
                PeekingCardStack(
                    cards: underlying,
                    isFaceDown: false,
                    scale: 0.92
                )

                interactiveTopCard(card: card)
                    .offset(y: PeekingCardStack.topCardOffset(forTotalCount: cards.count, scale: 0.92))
            } else {
                interactiveTopCard(card: card)
            }
        } else {
            placeholderCard
        }
    }

    private var stackHeight: CGFloat {
        guard let _ = cards.last else { return 98 * 0.95 }
        if showsStackWhenMultiple, cards.count > 1 {
            return PeekingCardStack.totalStackHeight(forTotalCount: cards.count, topScale: 0.95, peekScale: 0.92)
        } else {
            return 98 * 0.95
        }
    }
}
#endif
