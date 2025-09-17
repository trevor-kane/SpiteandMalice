#if canImport(SwiftUI)
import SwiftUI

struct HintOverlayView: View {
    var message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.black)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black.opacity(0.65))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Dismiss hint"))
            }
        }
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
