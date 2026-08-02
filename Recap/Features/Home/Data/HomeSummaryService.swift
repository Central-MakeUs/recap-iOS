import Foundation

@MainActor
protocol HomeSummaryLoading {
    func fetchSummary() async throws -> HomeSummaryContent
    func fetchRecentCaptures(page: Int, size: Int) async throws -> RecentCapturesPage
}

extension HomeSummaryLoading {
    func fetchRecentCaptures(page: Int, size: Int) async throws -> RecentCapturesPage {
        let cards = (try await fetchSummary()).recentCards
        return RecentCapturesPage(
            totalCount: cards.count,
            hasNext: false,
            cards: cards
        )
    }
}

@MainActor
final class HomeSummaryService: HomeSummaryLoading {
    private let networkClient: any NetworkClient

    init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchSummary() async throws -> HomeSummaryContent {
        let response: APIResponse<HomeSummaryDTO> = try await networkClient.send(
            APIEndpoint(
                method: .get,
                path: "/api/v1/home/summary",
                headers: ["Accept": "application/json"]
            )
            .authorized()
        )

        return HomeSummaryContent(dto: try response.requiredData())
    }

    func fetchRecentCaptures(page: Int, size: Int) async throws -> RecentCapturesPage {
        let response: APIResponse<RecentCapturesPageDTO> = try await networkClient.send(
            APIEndpoint(
                method: .get,
                path: "/api/v1/home/recent-captures",
                queryItems: [
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "size", value: String(size))
                ],
                headers: ["Accept": "application/json"]
            )
            .authorized()
        )
        return RecentCapturesPage(dto: try response.requiredData())
    }
}
