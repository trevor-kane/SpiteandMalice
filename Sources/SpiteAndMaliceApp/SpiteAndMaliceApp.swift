#if canImport(SwiftUI)
import SwiftUI
import AppKit

@main
struct SpiteAndMaliceApp: App {
    @StateObject private var viewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .background(WindowConfigurator(minSize: NSSize(width: 1180, height: 820)))
        }
        .windowResizability(.automatic)
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Game") {
                    viewModel.startNewGame()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandMenu("Gameplay") {
                Button("Undo Move") {
                    viewModel.undoLastAction()
                }
                .keyboardShortcut("z", modifiers: [.command])
                .disabled(!viewModel.canUndoTurn)

                Button("Hint") {
                    viewModel.provideHint()
                }
                .keyboardShortcut("h", modifiers: [.command])
                .disabled(!(viewModel.state.currentPlayer.isHuman && viewModel.state.status == .playing))

                Button("End Turn") {
                    viewModel.endTurnIfPossible()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!(viewModel.state.currentPlayer.isHuman && viewModel.state.phase == .waiting))

                Toggle(isOn: $viewModel.showsHelp) {
                    Text("Show Help Panel")
                }
                .keyboardShortcut("?", modifiers: [.shift, .command])
            }
            CommandGroup(after: .windowArrangement) {
                Button("Toggle Full Screen") {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
            }
        }
    }
}
#else
@main
struct SpiteAndMaliceApp {
    static func main() {
        fatalError("SpiteAndMaliceApp requires macOS and SwiftUI.")
    }
}
#endif
