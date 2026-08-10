import Foundation
import Synchronization
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

    /// 생성 직후에는 서버에 묻기 전이므로 동의하지 않은 상태로 시작한다.
    func testStoreStartsUnconsentedUntilServerAnswers() async throws {
        let consentedAt = Date(timeIntervalSince1970: 1_785_000_000)
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(hasConsented: true, consentedAt: consentedAt)
        )
        let store = AIDataTransferConsentStore(service: service)

        XCTAssertFalse(store.hasConsented)
        XCTAssertNil(store.consentedAt)
        XCTAssertEqual(service.fetchCallCount, 0)

        try await store.refresh()

        XCTAssertTrue(store.hasConsented)
        XCTAssertEqual(store.consentedAt, consentedAt)
    }

    func testRefreshReplacesStatusWithServerStatus() async throws {
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(hasConsented: true, consentedAt: .now)
        )
        let store = AIDataTransferConsentStore(service: service)
        try await store.refresh()
        XCTAssertTrue(store.hasConsented)

        service.status = AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil)
        try await store.refresh()

        XCTAssertFalse(store.hasConsented)
        XCTAssertNil(store.consentedAt)
    }

    func testGrantConsentUsesServerTimestamp() async throws {
        let consentedAt = Date(timeIntervalSince1970: 1_785_000_000)
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(
                hasConsented: true,
                consentedAt: consentedAt
            )
        )
        let store = AIDataTransferConsentStore(service: service)

        try await store.grantConsent()

        XCTAssertEqual(service.grantCallCount, 1)
        XCTAssertEqual(service.fetchCallCount, 1)
        XCTAssertTrue(store.hasConsented)
        XCTAssertEqual(store.consentedAt, consentedAt)
    }

    func testRevokeConsentClearsStatusOnlyAfterServerSuccess() async throws {
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(hasConsented: true, consentedAt: .now)
        )
        let store = AIDataTransferConsentStore(service: service)
        try await store.refresh()
        XCTAssertTrue(store.hasConsented)

        try await store.revokeConsent()

        XCTAssertEqual(service.revokeCallCount, 1)
        XCTAssertFalse(store.hasConsented)
        XCTAssertNil(store.consentedAt)
    }

    func testGrantFailureKeepsExistingStatus() async throws {
        let service = AIDataTransferConsentServiceStub(
            status: AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil),
            mutationError: APIError.offline
        )
        let store = AIDataTransferConsentStore(service: service)

        do {
            try await store.grantConsent()
            XCTFail("동의 API 실패가 전달되어야 한다")
        } catch {
            XCTAssertEqual(error as? APIError, .offline)
        }

        XCTAssertFalse(store.hasConsented)
        XCTAssertNil(store.consentedAt)
    }
}

private final class AIDataTransferConsentNetworkClientStub: NetworkClient {
    private let status: AIDataTransferConsentStatusDTO
    private let recordedEndpoints = Mutex<[APIEndpoint]>([])

    init(status: AIDataTransferConsentStatusDTO) {
        self.status = status
    }

    var endpoints: [APIEndpoint] {
        recordedEndpoints.withLock { $0 }
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        recordedEndpoints.withLock { $0.append(endpoint) }

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
