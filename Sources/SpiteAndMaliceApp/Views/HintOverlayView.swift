#if canImport(SwiftUI)
import SwiftUI

struct HintOverlayView: View {
    var message: String
    var recommendations: [GameViewModel.Hint.Recommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("Tip")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(.black.opacity(0.85))

            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            if !recommendations.isEmpty {
                Divider()
                    .background(Color.black.opacity(0.15))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Top plays")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))

                    ForEach(recommendations, id: \.rank) { recommendation in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(recommendation.rank)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .padding(6)
                                .background(Circle().fill(Color.black.opacity(0.08)))
                                .foregroundColor(.black.opacity(0.75))

                            Text(recommendation.detail)
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.78))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Text("Tap the Hint button again to dismiss.")
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.yellow.opacity(0.9))
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
        )
        .padding(.top, 8)
        .transition(.opacity.combined(with: .scale))
    }
}
#endif
