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

    private var baseSize: CGSize { CGSize(width: 70, height: 98) }

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
                VStack(spacing: 4) {
                    Text(card.displayName)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(CardPalette.textColor(for: card))
                        .shadow(radius: 1.5)
                    if card.isWild {
                        Text("Wild King")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    } else {
                        Text(card.value.accessibilityLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
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
}

struct CardPlaceholder: View {
    var title: String
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            .frame(width: 70, height: 98)
            .overlay(
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            )
    }
}
#endif
