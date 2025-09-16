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
            ZStack {
                if let top = pile.topCard?.card {
                    Button(action: { action?() }) {
                        CardView(card: top, isHighlighted: isActiveTarget, showsGlow: isActiveTarget)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { action?() }) {
                        CardPlaceholder(title: "Start with\nAce")
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isActiveTarget ? Color.yellow : Color.white.opacity(0.2), lineWidth: isActiveTarget ? 3 : 1)
                                    .shadow(color: isActiveTarget ? Color.yellow.opacity(0.5) : .clear, radius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay(alignment: .topTrailing) {
                if cardCount > 0 {
                    ProgressBadge(currentCount: cardCount)
                        .offset(x: 12, y: -12)
                }
            }
            .accessibilityLabel(Text(pileAccessibilityLabel))

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
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

private struct ProgressBadge: View {
    var currentCount: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: 32, height: 32)
            VStack(spacing: 2) {
                Text("\(currentCount) / \(BuildPile.targetSequenceCount)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}
#endif
