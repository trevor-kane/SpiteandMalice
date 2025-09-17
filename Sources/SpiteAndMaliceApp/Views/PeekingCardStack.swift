#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct PeekingCardStack: View {
    static let defaultPeekHeight: CGFloat = 32
    static let defaultPeekSpacing: CGFloat = 18
    static let defaultMaxPeekCount: Int = 4

    var cards: [Card]
    var isFaceDown: Bool
    var scale: CGFloat

    private var visibleCards: [Card] {
        Array(cards.suffix(Self.defaultMaxPeekCount))
    }

    var body: some View {
        let cardHeight = 98 * scale

        return ZStack(alignment: .topLeading) {
            ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                let isTopCard = index == visibleCards.indices.last
                CardView(card: card, isFaceDown: isFaceDown, scale: scale)
                    .mask(
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .frame(height: isTopCard ? cardHeight : Self.defaultPeekHeight)
                            Spacer(minLength: 0)
                        }
                    )
                    .offset(y: CGFloat(index) * Self.defaultPeekSpacing)
                    .shadow(color: Color.black.opacity(isTopCard ? 0.3 : 0.18), radius: isTopCard ? 8 : 4, y: isTopCard ? 6 : 3)
                    .zIndex(Double(index))
            }
        }
        .frame(height: cardHeight + CGFloat(max(visibleCards.count - 1, 0)) * Self.defaultPeekSpacing, alignment: .top)
        .clipped()
        .allowsHitTesting(false)
    }

    static func padding(forCardCount count: Int) -> CGFloat {
        CGFloat(min(count, defaultMaxPeekCount)) * defaultPeekSpacing
    }
}
#endif
