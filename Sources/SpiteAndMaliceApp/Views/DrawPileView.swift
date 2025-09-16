#if canImport(SwiftUI)
import SwiftUI

struct DrawPileView: View {
    var drawCount: Int
    var recycleCount: Int

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                CardPlaceholder(title: "Draw")
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)
                    )
                if drawCount > 0 {
                    Text("\(drawCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("Reshuffle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            Text("Draw pile")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
            if recycleCount > 0 {
                Text("Reserve: \(recycleCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}
#endif
