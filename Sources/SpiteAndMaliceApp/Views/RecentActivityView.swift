#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct RecentActivityView: View {
    var events: [GameEvent]
    var currentTurn: Int

    private var sections: [ActivitySectionModel] {
        var grouped: [ActivitySectionModel] = []

        for event in events {
            if let lastIndex = grouped.indices.last, grouped[lastIndex].turnIdentifier == event.turnIdentifier {
                grouped[lastIndex].events.append(event)
            } else {
                grouped.append(
                    ActivitySectionModel(
                        turnIdentifier: event.turnIdentifier,
                        round: event.turn,
                        events: [event]
                    )
                )
            }
        }

        return grouped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent Activity")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.94))

                Text("Turn \(currentTurn)")
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }

            if events.isEmpty {
                Text("No moves yet. Play a card to get things going!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(sections.enumerated()), id: \.element.turnIdentifier) { index, section in
                        ActivitySectionView(
                            section: section,
                            accentColor: accentColor(for: index)
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
    }

    private func accentColor(for index: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.38, green: 0.62, blue: 0.95),
            Color(red: 0.71, green: 0.43, blue: 0.92),
            Color(red: 0.46, green: 0.78, blue: 0.67)
        ]
        return palette[index % palette.count]
    }

    private struct ActivitySectionModel: Identifiable {
        var id = UUID()
        var turnIdentifier: Int
        var round: Int
        var events: [GameEvent]
    }

    private struct ActivitySectionView: View {
        var section: ActivitySectionModel
        var accentColor: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(section.turnIdentifier == 0 ? "Game start" : "Turn \(section.turnIdentifier)")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    if section.round > 0 {
                        Text("Round \(section.round)")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.78))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.12))
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(section.events.reversed()) { event in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.white.opacity(0.75))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(event.message)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.88))
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.28), accentColor.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accentColor.opacity(0.5), lineWidth: 1)
            )
        }
    }
}
#endif
