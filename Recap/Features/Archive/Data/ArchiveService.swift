import Foundation

@MainActor
protocol ArchiveLoading {
    func fetchHome() async throws -> ArchiveHomeContent
    func refreshHome(
        _ current: ArchiveHomeContent,
        scopes: ArchiveHomeRefreshScope
    ) async throws -> ArchiveHomeContent
    func fetchCards(
        scope: ArchiveDetailScope,
        sort: ArchiveSort
    ) async throws -> [CardSnapshot]
}

extension ArchiveLoading {
    func refreshHome(
        _ current: ArchiveHomeContent,
        scopes: ArchiveHomeRefreshScope
    ) async throws -> ArchiveHomeContent {
        try await fetchHome()
    }
}

@MainActor
final class ArchiveService: ArchiveLoading {
    private let networkClient: any NetworkClient

    init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchHome() async throws -> ArchiveHomeContent {
        async let types = fetchTypes()
        async let favorites = fetchFavorites()
        async let other = fetchOther(sort: .latest)

        return try await ArchiveHomeContent(
            summaries: types.map(CategorySummary.init(archiveDTO:)),
            favoriteCount: favorites.count,
            otherCount: other.count
        )
    }

    func refreshHome(
        _ current: ArchiveHomeContent,
        scopes: ArchiveHomeRefreshScope
    ) async throws -> ArchiveHomeContent {
        guard !scopes.isEmpty else {
            return current
        }
        guard scopes != .all else {
            return try await fetchHome()
        }

        var summaries = current.summaries
        var favoriteCount = current.favoriteCount
        var otherCount = current.otherCount

        if scopes.contains(.types) {
            summaries = try await fetchTypes().map(CategorySummary.init(archiveDTO:))
        }
        if scopes.contains(.favorites) {
            favoriteCount = try await fetchFavorites().count
        }
        if scopes.contains(.other) {
            otherCount = try await fetchOther(sort: .latest).count
        }

        return ArchiveHomeContent(
            summaries: summaries,
            favoriteCount: favoriteCount,
            otherCount: otherCount
        )
    }

    func fetchCards(
        scope: ArchiveDetailScope,
        sort: ArchiveSort
    ) async throws -> [CardSnapshot] {
        let captureList: ArchiveCaptureListDTO

        switch scope {
        case .favorites:
            captureList = try await fetchFavorites()
        case .category(.other):
            captureList = try await fetchOther(sort: sort)
        case .category(let category):
            captureList = try await fetchType(category, sort: sort)
        }

        return captureList.items.map(CardSnapshot.init(archiveDTO:))
    }

    private func fetchFavorites() async throws -> ArchiveCaptureListDTO {
        try await fetchCaptureList(
            path: "/api/v1/storage/favorites"
        )
    }

    private func fetchOther(sort: ArchiveSort) async throws -> ArchiveCaptureListDTO {
        try await fetchCaptureList(
            path: "/api/v1/storage/etc",
            sort: sort
        )
    }

    private func fetchType(
        _ category: CardCategory,
        sort: ArchiveSort
    ) async throws -> ArchiveCaptureListDTO {
        guard let typeCode = CardTypeCode(category: category), typeCode != .etc else {
            throw APIError.malformedRequest
        }

        return try await fetchCaptureList(
            path: "/api/v1/storage/types/\(typeCode.rawValue)/captures",
            sort: sort
        )
    }

    private func fetchCaptureList(
        path: String,
        sort: ArchiveSort? = nil
    ) async throws -> ArchiveCaptureListDTO {
        let response: APIResponse<ArchiveCaptureListDTO> = try await networkClient.send(
            storageEndpoint(path: path, sort: sort)
        )
        return try response.requiredData()
    }

    private func fetchTypes() async throws -> [ArchiveStorageTypeDTO] {
        let response: APIResponse<[ArchiveStorageTypeDTO]> = try await networkClient.send(
            storageEndpoint(path: "/api/v1/storage/types")
        )
        return try response.requiredData()
    }

    private func storageEndpoint(
        path: String,
        sort: ArchiveSort? = nil
    ) -> APIEndpoint {
        APIEndpoint(
            method: .get,
            path: path,
            queryItems: sort.map {
                [URLQueryItem(name: "sort", value: $0.rawValue)]
            } ?? [],
            headers: ["Accept": "application/json"]
        )
        .authorized()
    }
}
