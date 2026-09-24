import SwiftUI

@main
struct EchoWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .onAppear { WatchLink.shared.activate() }
        }
    }
}
