#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct CardPalette {
    static func background(for card: Card) -> LinearGradient {
        if card.isWild {
            return LinearGradient(colors: [Color.pinkBright, Color.orangeBright], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        switch card.value {
        case .ace, .two, .three:
            return LinearGradient(colors: [Color.blueSoft, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .four, .five, .six:
            return LinearGradient(colors: [Color.greenSoft, Color.tealBright], startPoint: .top, endPoint: .bottom)
        case .seven, .eight, .nine:
            return LinearGradient(colors: [Color.purpleSoft, Color.purple], startPoint: .leading, endPoint: .trailing)
        case .ten, .jack, .queen:
            return LinearGradient(colors: [Color.orangeSoft, Color.redSoft], startPoint: .topTrailing, endPoint: .bottomLeading)
        case .king:
            return LinearGradient(colors: [Color.orangeBright, Color.redStrong], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    static func textColor(for card: Card) -> Color {
        card.isWild ? .white : .white.opacity(0.95)
    }
}

private extension Color {
    static let blueSoft = Color(red: 0.42, green: 0.59, blue: 0.93)
    static let indigo = Color(red: 0.23, green: 0.34, blue: 0.74)
    static let greenSoft = Color(red: 0.36, green: 0.72, blue: 0.59)
    static let tealBright = Color(red: 0.18, green: 0.63, blue: 0.61)
    static let purpleSoft = Color(red: 0.56, green: 0.41, blue: 0.79)
    static let orangeSoft = Color(red: 0.98, green: 0.67, blue: 0.32)
    static let redSoft = Color(red: 0.91, green: 0.39, blue: 0.39)
    static let orangeBright = Color(red: 0.98, green: 0.51, blue: 0.26)
    static let redStrong = Color(red: 0.79, green: 0.17, blue: 0.32)
    static let pinkBright = Color(red: 0.95, green: 0.37, blue: 0.76)
}
#endif
