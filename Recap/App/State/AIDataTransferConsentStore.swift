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
    private let service: any AIDataTransferConsentServing
    private(set) var hasConsented: Bool
    private(set) var consentedAt: Date?

    init(
        service: any AIDataTransferConsentServing,
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults
        hasConsented = userDefaults.bool(forKey: Key.hasConsented)
        consentedAt = userDefaults.object(forKey: Key.consentedAt) as? Date
    }

    func refresh() async throws {
        let status = try await service.fetchConsentStatus()
        apply(status)
    }

    func grantConsent() async throws {
        try await service.grantConsent()
        let status = try await service.fetchConsentStatus()
        apply(status)
    }

    func revokeConsent() async throws {
        try await service.revokeConsent()
        apply(AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil))
    }

    private func apply(_ status: AIDataTransferConsentStatus) {
        hasConsented = status.hasConsented
        consentedAt = status.consentedAt
        userDefaults.set(status.hasConsented, forKey: Key.hasConsented)

        if let consentedAt = status.consentedAt {
            userDefaults.set(consentedAt, forKey: Key.consentedAt)
        } else {
            userDefaults.removeObject(forKey: Key.consentedAt)
        }
    }
}
