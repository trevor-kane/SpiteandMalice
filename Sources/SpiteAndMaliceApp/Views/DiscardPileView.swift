#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct DiscardPileView: View {
    var cards: [Card]
    var title: String
    var isHighlighted: Bool = false
    var isInteractive: Bool = false
    var action: (() -> Void)?
    var isRevealed: Bool = false
    var onRevealToggle: (() -> Void)?

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
        ZStack {
            if isRevealed && !cards.isEmpty {
                CardStackRevealView(cards: cards)
            } else if let card = cards.last {
                interactiveTopCard(card: card)
            } else {
                placeholderCard
            }
        }
        .overlay(alignment: .top) {
            if !cards.isEmpty {
                PilePeekHandle(action: onRevealToggle) {
                    HStack(spacing: 8) {
                        Text("\(cards.count)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        if onRevealToggle != nil {
                            Image(systemName: isRevealed ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                }
                .offset(y: -20)
            }
        }
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
            }
            .buttonStyle(.plain)
            .opacity(isInteractive ? 1 : 0.65)
        } else {
            CardPlaceholder(title: "Discard")
                .opacity(isInteractive ? 1 : 0.65)
        }
    }
}
#endif
