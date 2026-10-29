import SwiftUI

@main
struct EchoApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(\.locale, Copy.language())
                .preferredColorScheme(.dark)
                .statusBarHidden(false)
                .onChange(of: phase) { _, value in model.monetization.sceneChanged(active: value == .active) }
        }
    }
}
