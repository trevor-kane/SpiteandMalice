#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct PeekingCardStack: View {
    static let defaultPeekHeight: CGFloat = 36
    static let defaultPeekSpacing: CGFloat = 18
    static let defaultMaxPeekCount: Int = 5

    var cards: [Card]
    var isFaceDown: Bool
    var scale: CGFloat
    var showsFullTopCard: Bool = false

    private var visibleCards: [Card] {
        Array(cards.suffix(Self.defaultMaxPeekCount))
    }

    var body: some View {
        let cardHeight = 98 * scale

        return ZStack(alignment: .topLeading) {
            ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                let isTopCard = index == visibleCards.indices.last
                let drawsFullCard = showsFullTopCard && isTopCard
                CardView(card: card, isFaceDown: isFaceDown, scale: scale)
                    .mask(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .frame(height: drawsFullCard ? cardHeight : Self.defaultPeekHeight)
                    )
                    .offset(y: CGFloat(index) * Self.defaultPeekSpacing)
                    .shadow(color: Color.black.opacity(drawsFullCard ? 0.28 : 0.16), radius: drawsFullCard ? 8 : 4, y: drawsFullCard ? 6 : 3)
                    .zIndex(Double(index))
            }
        }
        .frame(
            width: 70 * scale,
            height: Self.stackHeight(forVisibleCount: visibleCards.count, scale: scale, showsFullTopCard: showsFullTopCard),
            alignment: .topLeading
        )
        .allowsHitTesting(false)
    }

    static func stackHeight(forVisibleCount visibleCount: Int, scale: CGFloat, showsFullTopCard: Bool) -> CGFloat {
        guard visibleCount > 0 else { return 0 }
        let cardHeight = 98 * scale
        let overlaps = max(visibleCount - 1, 0)
        let topHeight = showsFullTopCard ? cardHeight : defaultPeekHeight
        return topHeight + CGFloat(overlaps) * defaultPeekSpacing
    }

    static func topCardOffset(forTotalCount totalCount: Int) -> CGFloat {
        CGFloat(min(max(totalCount - 1, 0), defaultMaxPeekCount)) * defaultPeekSpacing
    }

    static func totalStackHeight(forTotalCount totalCount: Int, topScale: CGFloat) -> CGFloat {
        guard totalCount > 0 else { return 98 * topScale }
        let visible = min(max(totalCount - 1, 0), defaultMaxPeekCount)
        return (98 * topScale) + CGFloat(visible) * defaultPeekSpacing
    }
}
#endif
