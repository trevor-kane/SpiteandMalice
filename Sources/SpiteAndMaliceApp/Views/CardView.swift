#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct CardView: View {
    let card: Card
    var isFaceDown: Bool = false
    var isSelected: Bool = false
    var isHighlighted: Bool = false
    var showsGlow: Bool = false
    var scale: CGFloat = 1
    var resolvedValueOverride: CardValue?

    private var baseSize: CGSize { CGSize(width: 70, height: 98) }
    private var usesResolvedOverride: Bool { card.isWild && resolvedValueOverride != nil }
    private var resolvedValue: CardValue? { usesResolvedOverride ? resolvedValueOverride : nil }

    var body: some View {
        let size = CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isFaceDown ? AnyShapeStyle(Color.gray.opacity(0.5)) : AnyShapeStyle(CardPalette.background(for: card)))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(borderColor, lineWidth: isSelected ? 4 : 2)
                        .shadow(color: isHighlighted ? Color.white.opacity(0.8) : .clear, radius: isHighlighted ? 8 : 0)
                )
                .shadow(color: Color.black.opacity(0.35), radius: showsGlow ? 12 : 4, x: 0, y: showsGlow ? 12 : 6)
            if isFaceDown {
                VStack(spacing: 6) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Text("Spite &\nMalice")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                VStack(spacing: usesResolvedOverride ? 6 : 4) {
                    Text(primaryLabel)
                        .font(.system(size: usesResolvedOverride ? 40 : 34, weight: .heavy, design: .rounded))
                        .foregroundColor(CardPalette.textColor(for: card))
                        .shadow(radius: 1.5)
                    subtitleView
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .topLeading) {
            if usesResolvedOverride {
                KingBadge()
                    .offset(x: 8, y: 8)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.white
        } else if isHighlighted {
            return Color.yellow.opacity(0.9)
        } else {
            return Color.white.opacity(0.6)
        }
    }

    @ViewBuilder
    private var subtitleView: some View {
        if let resolvedValue {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("King as \(resolvedValue.accessibilityLabel)")
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.92))
        } else if card.isWild {
            Text("Wild King")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        } else {
            Text(card.value.accessibilityLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private var primaryLabel: String {
        if let resolvedValue {
            return resolvedValue.label
        }
        return card.displayName
    }
}

struct CardPlaceholder: View {
    var title: String
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .frame(width: 70, height: 98)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.32), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            )
            .overlay(
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.68))
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct KingBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 13, weight: .bold))
            Text("King")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(.white)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.55))
        )
    }
}
#endif
