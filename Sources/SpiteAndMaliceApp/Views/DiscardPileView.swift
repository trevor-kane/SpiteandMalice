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

    private let stackCardScale: CGFloat = 0.95

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
        ZStack(alignment: .top) {
            discardStack
        }
        .frame(height: stackHeight)
    }

    @ViewBuilder
    private func interactiveTopCard(card: Card) -> some View {
        let view = CardView(card: card, isHighlighted: isHighlighted, showsGlow: isHighlighted, scale: stackCardScale)
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
                    .scaleEffect(stackCardScale)
            }
            .buttonStyle(.plain)
            .opacity(isInteractive ? 1 : 0.65)
        } else {
            CardPlaceholder(title: "Discard")
                .scaleEffect(stackCardScale)
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
                    scale: stackCardScale
                )

                interactiveTopCard(card: card)
                    .offset(y: PeekingCardStack.topCardOffset(forTotalCount: cards.count, scale: stackCardScale))
            } else {
                interactiveTopCard(card: card)
            }
        } else {
            placeholderCard
        }
    }

    private var stackHeight: CGFloat {
        guard let _ = cards.last else { return 98 * stackCardScale }
        if showsStackWhenMultiple, cards.count > 1 {
            return PeekingCardStack.totalStackHeight(
                forTotalCount: cards.count,
                topScale: stackCardScale,
                peekScale: stackCardScale
            )
        }
        return 98 * stackCardScale
    }
}
#endif
