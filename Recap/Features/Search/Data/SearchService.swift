import Foundation

@MainActor
protocol SearchLoading {
    func search(
        query: String,
        scope: SearchScope,
        page: Int,
        size: Int
    ) async throws -> SearchPage
}

@MainActor
final class SearchService: SearchLoading {
    private let networkClient: any NetworkClient

    init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    func search(
        query: String,
        scope: SearchScope,
        page: Int,
        size: Int
    ) async throws -> SearchPage {
        let response: APIResponse<SearchResponseDTO> = try await networkClient.send(
            APIEndpoint(
                method: .get,
                path: "/api/v1/search",
                queryItems: searchQueryItems(
                    query: query,
                    scope: scope,
                    page: page,
                    size: size
                ),
                headers: ["Accept": "application/json"]
            )
            .authorized()
        )

        return SearchPage(dto: try response.requiredData())
    }

    private func searchQueryItems(
        query: String,
        scope: SearchScope,
        page: Int,
        size: Int
    ) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "scope", value: scope.queryValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]

        if let typeCode = scope.typeCode {
            items.append(URLQueryItem(name: "typeCode", value: typeCode.rawValue))
        }

        return items
    }
}
