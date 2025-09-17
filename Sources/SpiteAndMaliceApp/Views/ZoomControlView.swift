#if canImport(SwiftUI)
import SwiftUI

struct ZoomControlView: View {
    @Binding var zoomLevel: CGFloat

    private let range: ClosedRange<CGFloat> = 0.8...1.4

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "minus.magnifyingglass")
                    .foregroundColor(.white.opacity(0.85))
                Slider(value: $zoomLevel, in: range)
                    .tint(Color.white)
                Image(systemName: "plus.magnifyingglass")
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(width: 220)

            Text("\(Int(zoomLevel * 100))%")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.92)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, y: 6)
    }
}
#endif
