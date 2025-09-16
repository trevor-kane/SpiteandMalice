#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct CardStackRevealView: View {
    var cards: [Card]
    var isFaceDown: Bool = false

    private let cardScale: CGFloat = 0.92
    private let cardSpacing: CGFloat = 12

    private var orderedCards: [Card] { Array(cards.reversed()) }

    private var contentHeight: CGFloat {
        let cardHeight = 98 * cardScale
        let spacing = max(0, CGFloat(orderedCards.count - 1)) * cardSpacing
        return CGFloat(orderedCards.count) * cardHeight + spacing + 16
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: orderedCards.count > 4) {
            VStack(spacing: cardSpacing) {
                ForEach(orderedCards) { card in
                    CardView(
                        card: card,
                        isFaceDown: isFaceDown && card.id != orderedCards.first?.id,
                        scale: cardScale
                    )
                    .transition(
                        .move(edge: .bottom)
                            .combined(with: .opacity)
                    )
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .frame(
            width: 110,
            height: min(max(contentHeight, 160), 320)
        )
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 10)
    }
}
#endif
