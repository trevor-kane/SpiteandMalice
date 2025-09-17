#if canImport(SwiftUI)
import SwiftUI

struct PilePeekHandle<Content: View>: View {
    private let action: (() -> Void)?
    private let content: Content

    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        let handle = content
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(bubbleBackground)
            .overlay(bubbleStroke)
            .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
            .contentShape(Rectangle())

        Group {
            if let action {
                Button(action: action) {
                    handle
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
            } else {
                handle
            }
        }
    }

    private var bubbleBackground: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.28), Color.white.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(0.92)
    }

    private var bubbleStroke: some View {
        Capsule(style: .continuous)
            .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
    }
}
#endif
