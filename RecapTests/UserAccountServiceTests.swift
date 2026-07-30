import Foundation
import XCTest
@testable import Recap

@MainActor
final class UserAccountServiceTests: XCTestCase {
    func testFetchAccountInfoUsesAuthorizedUserEndpoint() async throws {
        let createdAt = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-07-28T12:00:00Z")
        )
        let client = UserAccountNetworkClientStub(
            responses: [
                "/api/v1/users/me": APIResponse(
                    success: true,
                    data: UserAccountInfoDTO(
                        platform: "kakao",
                        createdAt: createdAt
                    )
                )
            ]
        )
        let service = UserAccountService(networkClient: client)

        let accountInfo = try await service.fetchAccountInfo()

        XCTAssertEqual(accountInfo, UserAccountInfo(provider: .kakao, createdAt: createdAt))
        assertEndpoint(
            client.endpoints[0],
            method: .get,
            path: "/api/v1/users/me"
        )
    }

    func testFetchDataSummaryMapsCapturedCount() async throws {
        let client = UserAccountNetworkClientStub(
            responses: [
                "/api/v1/users/me/data-summary": APIResponse(
                    success: true,
                    data: UserDataSummaryDTO(capturedCount: 42)
                )
            ]
        )
        let service = UserAccountService(networkClient: client)

        let summary = try await service.fetchDataSummary()

        XCTAssertEqual(summary.capturedCount, 42)
        assertEndpoint(
            client.endpoints[0],
            method: .get,
            path: "/api/v1/users/me/data-summary"
        )
    }

    func testWithdrawalAndDataDeletionUseSeparateDeleteEndpoints() async throws {
        let client = UserAccountNetworkClientStub(
            responses: [
                "/api/v1/users/me": EmptyResponse(),
                "/api/v1/users/me/data": EmptyResponse()
            ]
        )
        let service = UserAccountService(networkClient: client)

        try await service.withdrawAccount()
        try await service.deleteAllData()

        assertEndpoint(
            client.endpoints[0],
            method: .delete,
            path: "/api/v1/users/me"
        )
        assertEndpoint(
            client.endpoints[1],
            method: .delete,
            path: "/api/v1/users/me/data"
        )
    }

    func testDataManagementModelClearsCountAfterSuccessfulDeletion() async {
        let service = PreviewUserAccountService(capturedCount: 7)
        var callbackCount = 0
        let model = DataManagementModel(
            service: service,
            accountDataDeleted: { callbackCount += 1 }
        )

        await model.loadDataSummary()
        XCTAssertEqual(model.capturedCount, 7)

        await model.deleteAllData()

        XCTAssertEqual(model.capturedCount, 0)
        XCTAssertEqual(callbackCount, 1)
        XCTAssertEqual(model.toast?.style, .success)
    }

    func testDataManagementModelDoesNotDeleteWhenCapturedCountIsZero() async {
        let service = DataDeletionServiceSpy(capturedCount: 0)
        let model = DataManagementModel(
            service: service,
            accountDataDeleted: {}
        )

        await model.loadDataSummary()
        await model.deleteAllData()

        XCTAssertFalse(model.canDeleteData)
        XCTAssertEqual(service.deleteCallCount, 0)
    }

    private func assertEndpoint(
        _ endpoint: APIEndpoint,
        method: APIEndpoint.Method,
        path: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(endpoint.method, method, file: file, line: line)
        XCTAssertEqual(endpoint.path, path, file: file, line: line)
        XCTAssertEqual(endpoint.authorization, .bearer, file: file, line: line)
        XCTAssertEqual(endpoint.headers["Accept"], "application/json", file: file, line: line)
    }
}

@MainActor
private final class DataDeletionServiceSpy: UserAccountServing {
    let capturedCount: Int
    private(set) var deleteCallCount = 0

    init(capturedCount: Int) {
        self.capturedCount = capturedCount
    }

    func fetchAccountInfo() async throws -> UserAccountInfo {
        UserAccountInfo(provider: .kakao, createdAt: .distantPast)
    }

    func fetchDataSummary() async throws -> UserDataSummary {
        UserDataSummary(capturedCount: capturedCount)
    }

    func withdrawAccount() async throws {}

    func deleteAllData() async throws {
        deleteCallCount += 1
    }
}

private final class UserAccountNetworkClientStub: NetworkClient, @unchecked Sendable {
    private let lock = NSLock()
    private var storedEndpoints: [APIEndpoint] = []
    private let responses: [String: Any]

    init(responses: [String: Any]) {
        self.responses = responses
    }

    var endpoints: [APIEndpoint] {
        lock.withLock { storedEndpoints }
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        lock.withLock {
            storedEndpoints.append(endpoint)
        }

        guard let response = responses[endpoint.path] as? Response else {
            throw APIError.decoding
        }
        return response
    }
}
