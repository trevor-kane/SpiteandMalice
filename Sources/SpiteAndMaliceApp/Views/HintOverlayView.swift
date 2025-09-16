#if canImport(SwiftUI)
import SwiftUI

struct HintOverlayView: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.85))
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
            )
            .padding(.top, 8)
            .transition(.opacity.combined(with: .scale))
    }
}
#endif
