import Foundation

extension MonetizationCoordinator {
    static func application() -> MonetizationCoordinator {
#if ECHO_ADMOB
        // Explicit SDK variant only; Release generation/build requires a real publisher App ID.
        return MonetizationCoordinator(privacy: PrivacyCoordinator(client: AdMobPrivacyClient()), provider: AdMobProvider())
#else
        // Google performs +load bootstrap validation even without start(). Do not link it
        // into the default preFree binary while publisher configuration is absent.
        return MonetizationCoordinator()
#endif
    }
}
