#if canImport(SwiftUI)
import SwiftUI

struct DrawPileView: View {
    var drawCount: Int
    var recycleCount: Int

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.28, green: 0.33, blue: 0.5), Color(red: 0.19, green: 0.22, blue: 0.36)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1.4)
                    )
                    .frame(width: 70, height: 98)

                Text("\(drawCount)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if recycleCount > 0 {
                    PileBadge {
                        Label("\(recycleCount)", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .labelStyle(.titleAndIcon)
                            .imageScale(.small)
                    }
                    .offset(x: -6, y: 8)
                }
            }
        }
    }
}
#endif
