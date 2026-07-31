import XCTest
@testable import Recap

@MainActor
final class AIDataTransferConsentStoreTests: XCTestCase {
    func testConsentPersistsAcrossStoreInstances() throws {
        let suiteName = "AIDataTransferConsentStoreTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = AIDataTransferConsentStore(userDefaults: userDefaults)
        XCTAssertFalse(store.hasConsented)

        store.grantConsent()

        let restoredStore = AIDataTransferConsentStore(userDefaults: userDefaults)
        XCTAssertTrue(restoredStore.hasConsented)
    }

    func testGrantConsentRecordsConsentedDate() throws {
        let store = try makeStore()
        let consentedAt = Date(timeIntervalSince1970: 1_785_000_000)

        store.grantConsent(at: consentedAt)

        XCTAssertEqual(store.consentedAt, consentedAt)
    }

    func testRevokeConsentClearsConsentAndDate() throws {
        let userDefaults = try makeUserDefaults()
        let store = AIDataTransferConsentStore(userDefaults: userDefaults)
        store.grantConsent()

        store.revokeConsent()

        XCTAssertFalse(store.hasConsented)
        XCTAssertNil(store.consentedAt)

        let restoredStore = AIDataTransferConsentStore(userDefaults: userDefaults)
        XCTAssertFalse(restoredStore.hasConsented)
        XCTAssertNil(restoredStore.consentedAt)
    }

    /// 날짜 저장 이전에 동의한 사용자는 날짜 없이 동의 상태만 유지한다.
    func testConsentWithoutStoredDateRemainsConsented() throws {
        let userDefaults = try makeUserDefaults()
        userDefaults.set(true, forKey: "aiDataTransferConsent.hasConsented")

        let store = AIDataTransferConsentStore(userDefaults: userDefaults)

        XCTAssertTrue(store.hasConsented)
        XCTAssertNil(store.consentedAt)
    }

    private func makeStore() throws -> AIDataTransferConsentStore {
        AIDataTransferConsentStore(userDefaults: try makeUserDefaults())
    }

    private func makeUserDefaults() throws -> UserDefaults {
        let suiteName = "AIDataTransferConsentStoreTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
