#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct DiscardPileView: View {
    var cards: [Card]
    var title: String
    var isHighlighted: Bool = false
    var isInteractive: Bool = false
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 6) {
            if let card = cards.last {
                Button(action: { action?() }) {
                    CardView(card: card, isHighlighted: isHighlighted, showsGlow: isHighlighted, scale: 0.95)
                        .overlay(countBadge)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { action?() }) {
                    CardPlaceholder(title: "Discard")
                        .overlay(countBadge)
                }
                .buttonStyle(.plain)
                .opacity(isInteractive ? 1 : 0.65)
            }
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
        }
        .opacity(isInteractive ? 1 : 0.85)
        .animation(.easeInOut(duration: 0.15), value: cards.count)
    }

    private var countBadge: some View {
        Group {
            if cards.count > 1 {
                Text("\(cards.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.45)))
                    .offset(x: 24, y: -32)
            }
        }
    }
}
#endif
