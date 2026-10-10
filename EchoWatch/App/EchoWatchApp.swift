import SwiftUI

@main
struct EchoWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(\.locale, Copy.language())
                .onAppear { WatchLink.shared.activate() }
        }
    }
}
