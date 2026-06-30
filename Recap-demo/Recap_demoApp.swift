import SwiftUI

@main
struct Recap_demoApp: App {
    init() {
        BackgroundOCRCoordinator.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
