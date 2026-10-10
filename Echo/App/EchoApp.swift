import SwiftUI

@main
struct EchoApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(\.locale, Copy.language())
                .preferredColorScheme(.dark)
                .statusBarHidden(false)
        }
    }
}
