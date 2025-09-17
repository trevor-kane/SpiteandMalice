#if canImport(SwiftUI)
import SwiftUI

struct PileBadge<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(badgeBackground)
            .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)
    }

    private var badgeBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.black.opacity(0.65), Color.black.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }
}
#endif
