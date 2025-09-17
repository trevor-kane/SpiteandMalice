#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct PeekingCardStack: View {
    static let defaultPeekHeight: CGFloat = 14
    static let defaultMaxPeekCount: Int = 3

    var cards: [Card]
    var isFaceDown: Bool
    var scale: CGFloat

    private var visibleCards: [Card] {
        Array(cards.suffix(Self.defaultMaxPeekCount))
    }

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                let offsetAmount = CGFloat(visibleCards.count - index) * Self.defaultPeekHeight
                CardView(card: card, isFaceDown: isFaceDown, scale: scale)
                    .opacity(0.55 + (Double(index) * 0.12))
                    .offset(y: -offsetAmount)
            }
        }
        .allowsHitTesting(false)
    }

    static func padding(forCardCount count: Int) -> CGFloat {
        CGFloat(min(count, defaultMaxPeekCount)) * defaultPeekHeight
    }
}
#endif
