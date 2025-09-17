#if canImport(SwiftUI)
import SwiftUI

struct HintOverlayView: View {
    var message: String
    var recommendations: [GameViewModel.Hint.Recommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.yellow.opacity(0.9))
                    .padding(10)
                    .background(Circle().fill(Color.yellow.opacity(0.18)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Helpful tip")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                    Text("Tap Hint again to dismiss")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                if !recommendations.isEmpty {
                    Divider()
                        .overlay(Color.white.opacity(0.12))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recommended plays")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.68))

                        ForEach(recommendations, id: \.rank) { recommendation in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(recommendation.rank)")
                                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color.yellow.opacity(0.2))
                                    )
                                    .foregroundColor(Color.yellow.opacity(0.9))

                                Text(recommendation.detail)
                                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.82))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.28, blue: 0.48).opacity(0.95), Color(red: 0.15, green: 0.18, blue: 0.32).opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 14, y: 6)
    }
}
#endif
