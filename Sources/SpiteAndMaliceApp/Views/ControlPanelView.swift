#if canImport(SwiftUI)
import SwiftUI

struct ControlPanelView: View {
    var onNewGame: () -> Void
    var onHint: () -> Void
    var onUndo: () -> Void
    var isHintDisabled: Bool
    var isHintPinned: Bool
    var isUndoDisabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onNewGame) {
                Label("New Game", systemImage: "arrow.counterclockwise.circle")
            }
            .buttonStyle(.borderedProminent)

            hintButton

            Button(action: onUndo) {
                Label("Undo Move", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
            .disabled(isUndoDisabled)
        }
    }

    @ViewBuilder
    private var hintButton: some View {
        if isHintPinned {
            Button(action: onHint) {
                Label("Hint", systemImage: "lightbulb.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.yellow.opacity(0.85))
        } else {
            Button(action: onHint) {
                Label("Hint", systemImage: "lightbulb")
            }
            .buttonStyle(.bordered)
            .disabled(isHintDisabled)
        }
    }
}
#endif
