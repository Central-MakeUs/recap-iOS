import Foundation

@MainActor
protocol UserAccountServing {
    func fetchAccountInfo() async throws -> UserAccountInfo
    func fetchDataSummary() async throws -> UserDataSummary
    func withdrawAccount() async throws
    func deleteAllData() async throws
}

@MainActor
final class UserAccountService: UserAccountServing {
    private let networkClient: any NetworkClient

    init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchAccountInfo() async throws -> UserAccountInfo {
        let response: APIResponse<UserAccountInfoDTO> = try await networkClient.send(
            userEndpoint(method: .get, path: "/api/v1/users/me")
        )
        return UserAccountInfo(dto: try response.requiredData())
    }

    func fetchDataSummary() async throws -> UserDataSummary {
        let response: APIResponse<UserDataSummaryDTO> = try await networkClient.send(
            userEndpoint(method: .get, path: "/api/v1/users/me/data-summary")
        )
        return UserDataSummary(dto: try response.requiredData())
    }

    func withdrawAccount() async throws {
        let _: EmptyResponse = try await networkClient.send(
            userEndpoint(method: .delete, path: "/api/v1/users/me")
        )
    }

    func deleteAllData() async throws {
        let _: EmptyResponse = try await networkClient.send(
            userEndpoint(method: .delete, path: "/api/v1/users/me/data")
        )
    }

    private func userEndpoint(method: APIEndpoint.Method, path: String) -> APIEndpoint {
        APIEndpoint(
            method: method,
            path: path,
            headers: ["Accept": "application/json"]
        )
        .authorized()
    }
}

nonisolated struct UserAccountInfo: Equatable, Sendable {
    let provider: AuthProvider?
    let createdAt: Date

    init(provider: AuthProvider?, createdAt: Date) {
        self.provider = provider
        self.createdAt = createdAt
    }

    init(dto: UserAccountInfoDTO) {
        provider = AuthProvider(serverValue: dto.platform)
        createdAt = dto.createdAt
    }
}

nonisolated struct UserDataSummary: Equatable, Sendable {
    let capturedCount: Int

    init(capturedCount: Int) {
        self.capturedCount = capturedCount
    }

    init(dto: UserDataSummaryDTO) {
        capturedCount = dto.capturedCount
    }
}

nonisolated struct UserAccountInfoDTO: Decodable, Equatable, Sendable {
    let platform: String?
    let createdAt: Date
}

nonisolated struct UserDataSummaryDTO: Decodable, Equatable, Sendable {
    let capturedCount: Int
}

private extension AuthProvider {
    nonisolated init?(serverValue: String?) {
        switch serverValue?.lowercased() {
        case "kakao":
            self = .kakao
        case "apple":
            self = .apple
        default:
            return nil
        }
    }
}
