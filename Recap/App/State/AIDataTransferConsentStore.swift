import Foundation
import Observation

@MainActor
@Observable
final class AIDataTransferConsentStore {
    private enum Key {
        static let hasConsented = "aiDataTransferConsent.hasConsented"
        static let consentedAt = "aiDataTransferConsent.consentedAt"
    }

    private let userDefaults: UserDefaults
    private(set) var hasConsented: Bool
    private(set) var consentedAt: Date?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        hasConsented = userDefaults.bool(forKey: Key.hasConsented)
        consentedAt = userDefaults.object(forKey: Key.consentedAt) as? Date
    }

    func grantConsent(at date: Date = .now) {
        hasConsented = true
        consentedAt = date
        userDefaults.set(true, forKey: Key.hasConsented)
        userDefaults.set(date, forKey: Key.consentedAt)
    }

    func revokeConsent() {
        hasConsented = false
        consentedAt = nil
        userDefaults.set(false, forKey: Key.hasConsented)
        userDefaults.removeObject(forKey: Key.consentedAt)
    }
}
