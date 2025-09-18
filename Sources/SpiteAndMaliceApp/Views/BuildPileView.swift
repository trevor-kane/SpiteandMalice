#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct BuildPileView: View {
    let pile: BuildPile
    var title: String
    var isActiveTarget: Bool
    var action: (() -> Void)?

    private var cardCount: Int { pile.cards.count }

    var body: some View {
        VStack(spacing: 10) {
            pileContent
                .accessibilityLabel(Text(pileAccessibilityLabel))

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    @ViewBuilder
    private var pileContent: some View {
        if let top = pile.topCard {
            ZStack(alignment: .topLeading) {
                if cardCount > 1 {
                    PeekingCardStack(
                        cards: Array(pile.cards.dropLast().map { $0.card }),
                        isFaceDown: false,
                        scale: 0.94
                    )
                }
                interactiveCard(for: top)
                    .offset(y: PeekingCardStack.topCardOffset(forTotalCount: cardCount, scale: 0.94))
            }
            .frame(height: PeekingCardStack.totalStackHeight(forTotalCount: cardCount, topScale: 1, peekScale: 0.94))
        } else {
            placeholderCard
        }
    }

    @ViewBuilder
    private func interactiveCard(for playedCard: PlayedCard) -> some View {
        let resolvedOverride = playedCard.card.isWild ? playedCard.resolvedValue : nil
        let view = CardView(
            card: playedCard.card,
            isHighlighted: isActiveTarget,
            showsGlow: isActiveTarget,
            resolvedValueOverride: resolvedOverride
        )
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
        let placeholder = CardPlaceholder(title: "Start\nwith 1")
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActiveTarget ? Color.yellow : Color.white.opacity(0.2), lineWidth: isActiveTarget ? 3 : 1)
                    .shadow(color: isActiveTarget ? Color.yellow.opacity(0.5) : .clear, radius: 8)
            )
        if let action {
            Button(action: action) {
                placeholder
            }
            .buttonStyle(.plain)
        } else {
            placeholder
        }
    }

    private var pileAccessibilityLabel: String {
        if let top = pile.topCard?.card {
            return "Build pile showing \(top.value.accessibilityLabel)."
        } else {
            return "Empty build pile awaiting an Ace."
        }
    }
}
#endif
