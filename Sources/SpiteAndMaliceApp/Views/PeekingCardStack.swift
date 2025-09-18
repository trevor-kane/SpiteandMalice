#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct PeekingCardStack: View {
    static let defaultPeekSpacing: CGFloat = 26
    static let defaultMaxPeekCount: Int = 5
    var cards: [Card]
    var isFaceDown: Bool
    var scale: CGFloat

    private var visibleCards: [Card] {
        Array(cards.suffix(Self.defaultMaxPeekCount))
    }

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                let total = visibleCards.count
                CardView(card: card, isFaceDown: isFaceDown, scale: scale)
                    .overlay(alignment: .top) {
                        if !isFaceDown {
                            peekLabel(for: card, scale: scale)
                        }
                    }
                    .offset(y: offset(forIndex: index))
                    .shadow(color: Color.black.opacity(shadowOpacity(forIndex: index, totalCount: total)), radius: 6, y: 4)
                    .zIndex(Double(index))
            }
        }
        .frame(
            width: stackWidth,
            height: Self.stackHeight(forVisibleCount: visibleCards.count, scale: scale),
            alignment: .top
        )
        .allowsHitTesting(false)
    }

    private var stackWidth: CGFloat { 70 * scale }

    private func offset(forIndex index: Int) -> CGFloat {
        CGFloat(index) * Self.spacing(for: scale)
    }

    private func shadowOpacity(forIndex index: Int, totalCount: Int) -> Double {
        guard totalCount > 1 else { return 0.2 }
        let depth = totalCount - index - 1
        return Double(0.18 + (CGFloat(depth) * 0.05))
    }

    private func peekLabel(for card: Card, scale: CGFloat) -> some View {
        Text(card.displayName)
            .font(.system(size: 14 * scale, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 6 * scale)
            .padding(.vertical, 2.5 * scale)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.55))
            )
            .padding(.top, 6 * scale)
            .opacity(0.95)
    }

    private static func spacing(for scale: CGFloat) -> CGFloat {
        defaultPeekSpacing * max(scale, 0.82)
    }

    static func stackHeight(forVisibleCount visibleCount: Int, scale: CGFloat) -> CGFloat {
        guard visibleCount > 0 else { return 0 }
        let spacing = Self.spacing(for: scale)
        let lastOffset = CGFloat(visibleCount - 1) * spacing
        let lastCardHeight = 98 * scale
        return lastOffset + lastCardHeight
    }

    static func topCardOffset(forTotalCount totalCount: Int, scale: CGFloat) -> CGFloat {
        guard totalCount > 0 else { return 0 }
        let visible = min(max(totalCount - 1, 0), defaultMaxPeekCount)
        return CGFloat(visible) * Self.spacing(for: scale)
    }

    static func totalStackHeight(forTotalCount totalCount: Int, topScale: CGFloat, peekScale: CGFloat) -> CGFloat {
        guard totalCount > 0 else { return 98 * topScale }
        return (98 * topScale) + topCardOffset(forTotalCount: totalCount, scale: peekScale)
    }
}
#endif
