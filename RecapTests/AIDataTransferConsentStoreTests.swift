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
}
