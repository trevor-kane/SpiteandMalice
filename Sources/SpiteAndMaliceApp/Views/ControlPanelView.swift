#if canImport(SwiftUI)
import SwiftUI

struct ControlPanelView: View {
    var onNewGame: () -> Void
    var onHint: () -> Void
    var onUndo: () -> Void
    var onEndTurn: () -> Void
    var isHintDisabled: Bool
    var isUndoDisabled: Bool
    var isEndTurnDisabled: Bool
    @Binding var showsHelp: Bool

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onNewGame) {
                Label("New Game", systemImage: "arrow.counterclockwise.circle")
            }
            .buttonStyle(.borderedProminent)

            Button(action: onHint) {
                Label("Hint", systemImage: "lightbulb")
            }
            .buttonStyle(.bordered)
            .disabled(isHintDisabled)

            Button(action: onUndo) {
                Label("Undo Move", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
            .disabled(isUndoDisabled)

            Button(action: onEndTurn) {
                Label("End Turn", systemImage: "flag.checkered")
            }
            .buttonStyle(.bordered)
            .disabled(isEndTurnDisabled)

            Toggle(isOn: $showsHelp.animation()) {
                Label("Show Help", systemImage: "questionmark.circle")
            }
            .toggleStyle(.switch)
            .foregroundStyle(.white.opacity(0.85))
        }
    }
}
#endif
