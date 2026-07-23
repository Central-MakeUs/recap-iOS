import Foundation

@MainActor
protocol HomeSummaryLoading {
    func fetchSummary() async throws -> HomeSummaryContent
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
}
