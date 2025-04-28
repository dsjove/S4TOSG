import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Compile-time Decision", destination: CompileTimeDecisionExampleView())
                NavigationLink("Compositional Design", destination: CompositionalExampleView())
            }
            .navigationTitle("Examples")
        }
    }
}

@main
struct SFTOSGApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
