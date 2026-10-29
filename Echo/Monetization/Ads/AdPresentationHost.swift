import UIKit

@MainActor
enum AdPresentationHost {
    static func controller(allowExistingSheet: Bool = false) -> UIViewController? {
        guard UIApplication.shared.applicationState == .active,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              var root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return nil }
        if allowExistingSheet {
            while let next = root.presentedViewController { root = next }
        }
        guard root.presentedViewController == nil, !root.isBeingPresented, !root.isBeingDismissed,
              root.viewIfLoaded?.window != nil else { return nil }
        return root
    }
}
