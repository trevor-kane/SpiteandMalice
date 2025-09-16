#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct StockPileView: View {
    var card: Card?
    var remainingCount: Int
    var isFaceDown: Bool
    var isHighlighted: Bool = false
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 6) {
            Button(action: { action?() }) {
                ZStack {
                    if let card {
                        CardView(card: card, isFaceDown: isFaceDown, isHighlighted: isHighlighted, showsGlow: isHighlighted, scale: 1.05)
                    } else {
                        CardPlaceholder(title: "Stock")
                    }
                }
                .overlay(countBadge)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(accessibilityLabel))

            Text("Stock")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var countBadge: some View {
        Text("\(remainingCount)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(6)
            .background(Circle().fill(Color.black.opacity(0.45)))
            .offset(x: 28, y: -36)
    }

    private var accessibilityLabel: String {
        if let card, !isFaceDown {
            return "Stock pile showing \(card.value.accessibilityLabel) with \(remainingCount) cards remaining."
        } else {
            return "Stock pile with \(remainingCount) cards remaining."
        }
    }
}
#endif
