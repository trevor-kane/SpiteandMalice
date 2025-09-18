#if canImport(SwiftUI)
import SwiftUI

struct PlayerHandSummaryView: View {
    var title: String
    var count: Int
    var gradientColors: [Color]
    var borderColor: Color
    var titleColor: Color
    var countColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(titleColor)

            Text("\(count)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(countColor)
        }
        .frame(minWidth: 88)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1.2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) count: \(count)"))
    }
}
#endif
