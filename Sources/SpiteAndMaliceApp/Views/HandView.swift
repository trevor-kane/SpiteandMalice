#if canImport(SwiftUI)
import SwiftUI
import SpiteAndMaliceCore

struct HandView: View {
    var cards: [Card]
    var selectedCardID: UUID?
    var tapAction: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(cards.indices), id: \.self) { index in
                let card = cards[index]
                Button(action: { tapAction(index) }) {
                    CardView(card: card, isSelected: card.id == selectedCardID, showsGlow: card.id == selectedCardID)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Hand card \(card.value.accessibilityLabel)"))
            }
            if cards.count < GameEngine.handLimit {
                ForEach(0..<(GameEngine.handLimit - cards.count), id: \.self) { _ in
                    CardPlaceholder(title: "Drawn")
                        .opacity(0.4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
#endif
