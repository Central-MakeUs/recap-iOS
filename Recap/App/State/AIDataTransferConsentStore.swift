import Foundation
import Observation

@MainActor
@Observable
final class AIDataTransferConsentStore {
    private enum Key {
        static let hasConsented = "aiDataTransferConsent.hasConsented"
    }

    private let userDefaults: UserDefaults
    private(set) var hasConsented: Bool

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        hasConsented = userDefaults.bool(forKey: Key.hasConsented)
    }

    func grantConsent() {
        hasConsented = true
        userDefaults.set(true, forKey: Key.hasConsented)
    }
}
