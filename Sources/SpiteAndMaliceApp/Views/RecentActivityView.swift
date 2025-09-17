#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct RecentActivityView: View {
    var events: [GameEvent]

    private static let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent activity")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }

            if events.isEmpty {
                Text("No moves yet. Play a card to get things going!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            } else {
                VStack(spacing: 14) {
                    ForEach(events) { event in
                        ActivityRow(event: event)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.04))
        )
    }

    private struct ActivityRow: View {
        var event: GameEvent

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.55))
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.message)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.82))
                        .multilineTextAlignment(.leading)
                    Text(Self.relativeTime(from: event.timestamp))
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.02))
            )
        }

        private static func relativeTime(from date: Date) -> String {
            let now = Date()
            let formatted = RecentActivityView.formatter.localizedString(for: date, relativeTo: now)
            return formatted
        }
    }
}
#endif
