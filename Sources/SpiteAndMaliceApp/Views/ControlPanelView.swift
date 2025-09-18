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
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onNewGame) {
                Label("New Game", systemImage: "arrow.counterclockwise.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack(spacing: 12) {
                hintButton
                    .frame(maxWidth: .infinity)

                Button(action: onUndo) {
                    Label("Undo Move", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isUndoDisabled)
            }
        }
    }

    @ViewBuilder
    private var hintButton: some View {
        if isHintPinned {
            Button(action: onHint) {
                Label("Hint", systemImage: "lightbulb.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.yellow.opacity(0.85))
            .controlSize(.large)
        } else {
            Button(action: onHint) {
                Label("Hint", systemImage: "lightbulb")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isHintDisabled)
        }
    }
}
#endif
