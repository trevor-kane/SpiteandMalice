#if canImport(SwiftUI)
import SwiftUI

@main
struct SpiteAndMaliceApp: App {
    @StateObject private var viewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Game") {
                    viewModel.startNewGame()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandMenu("Gameplay") {
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
