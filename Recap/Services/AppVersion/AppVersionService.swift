import Foundation

@MainActor
protocol AppVersionChecking {
    func checkCurrentVersion() async throws -> AppVersionStatus
}

@MainActor
final class AppVersionService: AppVersionChecking {
    private let networkClient: any NetworkClient
    private let currentVersion: String

    init(networkClient: any NetworkClient, bundle: Bundle = .main) {
        self.networkClient = networkClient
        currentVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "0.0.0"
    }

    init(networkClient: any NetworkClient, currentVersion: String) {
        self.networkClient = networkClient
        self.currentVersion = currentVersion
    }

    func checkCurrentVersion() async throws -> AppVersionStatus {
        let response: APIResponse<AppVersionStatusDTO> = try await networkClient.send(
            APIEndpoint(
                method: .get,
                path: "/api/v1/app/version-check",
                queryItems: [
                    URLQueryItem(name: "platform", value: "IOS"),
                    URLQueryItem(name: "version", value: currentVersion)
                ],
                headers: ["Accept": "application/json"],
                cachePolicy: .reloadIgnoringLocalCacheData
            )
        )
        return AppVersionStatus(dto: try response.requiredData())
    }
}

nonisolated struct AppVersionStatus: Equatable, Identifiable, Sendable {
    var id: String { minimumVersion ?? "required-update" }
    let requiresUpdate: Bool
    let minimumVersion: String?
    let updateURL: URL?

    init(requiresUpdate: Bool, minimumVersion: String?, updateURL: URL?) {
        self.requiresUpdate = requiresUpdate
        self.minimumVersion = minimumVersion
        self.updateURL = updateURL
    }

    init(dto: AppVersionStatusDTO) {
        requiresUpdate = dto.forceUpdate
        minimumVersion = dto.minimumVersion
        updateURL = dto.updateUrl.flatMap(URL.init(string:))
    }
}

nonisolated struct AppVersionStatusDTO: Decodable, Equatable, Sendable {
    let forceUpdate: Bool
    let minimumVersion: String?
    let updateUrl: String?
}

@MainActor
final class PreviewAppVersionService: AppVersionChecking {
    private let status: AppVersionStatus

    init(status: AppVersionStatus = .init(
        requiresUpdate: false,
        minimumVersion: nil,
        updateURL: nil
    )) {
        self.status = status
    }

    func checkCurrentVersion() async throws -> AppVersionStatus { status }
}
