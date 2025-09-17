#if canImport(SwiftUI)
import SwiftUI

struct ControlPanelView: View {
    var onNewGame: () -> Void
    var onHint: () -> Void
    var onUndo: () -> Void
    var isHintDisabled: Bool
    var isHintActive: Bool
    var isUndoDisabled: Bool
    @Binding var showsHelp: Bool

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

            Toggle(isOn: $showsHelp.animation()) {
                Label("Show Help", systemImage: "questionmark.circle")
            }
            .toggleStyle(.switch)
            .foregroundStyle(.white.opacity(0.85))
        }
    }

    @ViewBuilder
    private var hintButton: some View {
        if isHintActive {
            Button(action: onHint) {
                Label("Hint", systemImage: "lightbulb.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.yellow.opacity(0.85))
            .disabled(true)
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
