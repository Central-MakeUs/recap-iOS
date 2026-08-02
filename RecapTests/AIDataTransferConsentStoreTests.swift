import Foundation
import XCTest
@testable import Recap

@MainActor
final class AIDataTransferConsentStoreTests: XCTestCase {
    func testConsentServiceUsesProtectedUserConsentEndpoints() async throws {
        let consentedAt = Date(timeIntervalSince1970: 1_785_000_000)
        let networkClient = AIDataTransferConsentNetworkClientStub(
            status: AIDataTransferConsentStatusDTO(
                consented: true,
                consentedAt: consentedAt
            )
        )
        let service = AIDataTransferConsentService(networkClient: networkClient)

        let status = try await service.fetchConsentStatus()
        try await service.grantConsent()
        try await service.revokeConsent()

        XCTAssertEqual(status, .init(hasConsented: true, consentedAt: consentedAt))
        XCTAssertEqual(networkClient.endpoints.map(\.method), [.get, .post, .delete])
        XCTAssertTrue(networkClient.endpoints.allSatisfy {
            $0.path == "/api/v1/users/me/consent" && $0.authorization == .bearer
        })
    }

    func testRefreshReplacesCachedConsentWithServerStatus() async throws {
        let userDefaults = try makeUserDefaults()
        userDefaults.set(true, forKey: "aiDataTransferConsent.hasConsented")
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil)
        )
        let store = AIDataTransferConsentStore(service: service, userDefaults: userDefaults)
        XCTAssertTrue(store.hasConsented)

        try await store.refresh()

        XCTAssertFalse(store.hasConsented)
        XCTAssertNil(store.consentedAt)
        XCTAssertFalse(userDefaults.bool(forKey: "aiDataTransferConsent.hasConsented"))
    }

    func testGrantConsentUsesServerTimestampAndPersistsItAsCache() async throws {
        let consentedAt = Date(timeIntervalSince1970: 1_785_000_000)
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(
                hasConsented: true,
                consentedAt: consentedAt
            )
        )
        let userDefaults = try makeUserDefaults()
        let store = AIDataTransferConsentStore(service: service, userDefaults: userDefaults)

        try await store.grantConsent()

        XCTAssertEqual(service.grantCallCount, 1)
        XCTAssertEqual(service.fetchCallCount, 1)
        XCTAssertTrue(store.hasConsented)
        XCTAssertEqual(store.consentedAt, consentedAt)

        let restoredStore = AIDataTransferConsentStore(
            service: service,
            userDefaults: userDefaults
        )
        XCTAssertTrue(restoredStore.hasConsented)
        XCTAssertEqual(restoredStore.consentedAt, consentedAt)
    }

    func testRevokeConsentClearsCacheOnlyAfterServerSuccess() async throws {
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(hasConsented: true, consentedAt: .now)
        )
        let userDefaults = try makeUserDefaults()
        let store = AIDataTransferConsentStore(service: service, userDefaults: userDefaults)
        try await store.refresh()

        try await store.revokeConsent()

        XCTAssertEqual(service.revokeCallCount, 1)
        XCTAssertFalse(store.hasConsented)
        XCTAssertNil(store.consentedAt)
        XCTAssertFalse(userDefaults.bool(forKey: "aiDataTransferConsent.hasConsented"))
    }

    func testGrantFailureKeepsExistingCachedStatus() async throws {
        let userDefaults = try makeUserDefaults()
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil),
            mutationError: APIError.offline
        )
        let store = AIDataTransferConsentStore(service: service, userDefaults: userDefaults)

        do {
            try await store.grantConsent()
            XCTFail("동의 API 실패가 전달되어야 한다")
        } catch {
            XCTAssertEqual(error as? APIError, .offline)
        }

        XCTAssertFalse(store.hasConsented)
        XCTAssertNil(store.consentedAt)
    }

    private func makeUserDefaults() throws -> UserDefaults {
        let suiteName = "AIDataTransferConsentStoreTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}

private final class AIDataTransferConsentNetworkClientStub: NetworkClient, @unchecked Sendable {
    private let lock = NSLock()
    private let status: AIDataTransferConsentStatusDTO
    private var recordedEndpoints: [APIEndpoint] = []

    init(status: AIDataTransferConsentStatusDTO) {
        self.status = status
    }

    var endpoints: [APIEndpoint] {
        lock.withLock { recordedEndpoints }
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        lock.withLock { recordedEndpoints.append(endpoint) }

        if Response.self == EmptyResponse.self,
           let response = EmptyResponse() as? Response {
            return response
        }

        let envelope = APIResponse(success: true, data: status)
        guard let response = envelope as? Response else {
            throw APIError.decoding
        }
        return response
    }
}

@MainActor
private final class AIDataTransferConsentServiceStub: AIDataTransferConsentServing {
    var status: AIDataTransferConsentStatus
    let mutationError: Error?
    private(set) var fetchCallCount = 0
    private(set) var grantCallCount = 0
    private(set) var revokeCallCount = 0

    init(
        status: AIDataTransferConsentStatus,
        mutationError: Error? = nil
    ) {
        self.status = status
        self.mutationError = mutationError
    }

    func fetchConsentStatus() async throws -> AIDataTransferConsentStatus {
        fetchCallCount += 1
        return status
    }

    func grantConsent() async throws {
        grantCallCount += 1
        if let mutationError { throw mutationError }
    }

    func revokeConsent() async throws {
        revokeCallCount += 1
        if let mutationError { throw mutationError }
        status = AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil)
    }
}
