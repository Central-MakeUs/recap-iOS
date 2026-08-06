import Synchronization
import XCTest
@testable import Recap

@MainActor
final class AppVersionServiceTests: XCTestCase {
    func testVersionCheckUsesPublicIOSCurrentVersionEndpoint() async throws {
        let client = AppVersionNetworkClientStub(
            response: APIResponse(
                success: true,
                data: AppVersionStatusDTO(
                    forceUpdate: true,
                    minimumVersion: "2.0.0",
                    updateUrl: "https://apps.apple.com/app/id123"
                )
            )
        )
        let service = AppVersionService(
            networkClient: client,
            currentVersion: "1.4.0"
        )

        let status = try await service.checkCurrentVersion()

        XCTAssertTrue(status.requiresUpdate)
        XCTAssertEqual(status.minimumVersion, "2.0.0")
        XCTAssertEqual(status.updateURL?.absoluteString, "https://apps.apple.com/app/id123")

        let endpoint = try XCTUnwrap(client.endpoint)
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path, "/api/v1/app/version-check")
        XCTAssertEqual(endpoint.authorization, .none)
        XCTAssertEqual(endpoint.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: endpoint.queryItems.map { ($0.name, $0.value) }),
            ["platform": "IOS", "version": "1.4.0"]
        )
    }
}

private final class AppVersionNetworkClientStub: NetworkClient {
    private let response: any Sendable
    private let recordedEndpoint = Mutex<APIEndpoint?>(nil)

    init<Response: Sendable>(response: Response) {
        self.response = response
    }

    var endpoint: APIEndpoint? {
        recordedEndpoint.withLock { $0 }
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        recordedEndpoint.withLock { $0 = endpoint }
        guard let response = response as? Response else {
            throw APIError.decoding
        }
        return response
    }
}
