#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct BuildPileView: View {
    let pile: BuildPile
    var title: String
    var isActiveTarget: Bool
    var action: (() -> Void)?
    var isRevealed: Bool = false
    var onRevealToggle: (() -> Void)?

    private var cardCount: Int { pile.cards.count }

    var body: some View {
        VStack(spacing: 10) {
            pileContent
                .overlay(alignment: .topLeading) {
                    if cardCount > 0 && !isRevealed {
                        PileBadge {
                            Text("\(cardCount) / \(BuildPile.targetSequenceCount)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .padding(8)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if cardCount > 0, let onRevealToggle {
                        Button(action: onRevealToggle) {
                            PileBadge {
                                HStack(spacing: 6) {
                                    Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(isRevealed ? "Hide" : "View")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                }
                .accessibilityLabel(Text(pileAccessibilityLabel))
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isRevealed)

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    @ViewBuilder
    private var pileContent: some View {
        if isRevealed && cardCount > 0 {
            CardStackRevealView(cards: pile.cards.map { $0.card })
        } else if let top = pile.topCard {
            interactiveCard(for: top)
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
        let placeholder = CardPlaceholder(title: "Start with\nAce")
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
