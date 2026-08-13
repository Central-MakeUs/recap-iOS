import Synchronization
import XCTest
@testable import Recap

@MainActor
final class HomeSummaryTests: XCTestCase {
    override func tearDown() {
        HomeSummaryURLProtocol.reset()
        super.tearDown()
    }

    func testSummaryResponseMapsServerFieldsToHomeContent() throws {
        let response = try JSONDecoder.recapAPI.decode(
            APIResponse<HomeSummaryDTO>.self,
            from: Data(Self.summaryJSON.utf8)
        )

        let content = HomeSummaryContent(dto: try response.requiredData())
        let recentCard = try XCTUnwrap(content.recentCards.first)
        let favoriteCard = try XCTUnwrap(content.favoriteCards.first)
        let topType = try XCTUnwrap(content.frequentTypes.first)

        XCTAssertEqual(recentCard.captureID, 101)
        XCTAssertEqual(recentCard.collection, .shopping)
        XCTAssertEqual(recentCard.thumbnailURL?.absoluteString, "https://images.example.com/101.jpg")
        XCTAssertEqual(
            recentCard.organizedAt,
            ISO8601DateFormatter().date(from: "2026-07-23T01:02:03Z")
        )
        XCTAssertEqual(favoriteCard.captureID, 102)
        XCTAssertTrue(favoriteCard.isFavorite)
        XCTAssertEqual(topType.kind, .career)
        XCTAssertEqual(topType.count, 4)
        XCTAssertEqual(
            topType.representativeThumbnailURL?.absoluteString,
            "https://images.example.com/job.jpg"
        )
        XCTAssertTrue(content.hasAnyCapture)
    }

    func testHomeServiceUsesProtectedSummaryEndpoint() async throws {
        let dto = try JSONDecoder.recapAPI.decode(
            APIResponse<HomeSummaryDTO>.self,
            from: Data(Self.summaryJSON.utf8)
        )
        let networkClient = HomeNetworkClientStub(response: dto)
        let service = HomeSummaryService(networkClient: networkClient)

        _ = try await service.fetchSummary()

        let endpoint = try XCTUnwrap(networkClient.lastEndpoint)
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path, "/api/v1/home/summary")
        XCTAssertEqual(endpoint.authorization, .bearer)
        XCTAssertEqual(endpoint.headers["Accept"], "application/json")
    }

    func testRecentCapturesUsesPagedProtectedEndpoint() async throws {
        let dto = RecentCapturesPageDTO(
            count: 1,
            hasNext: true,
            items: [
                HomeCaptureSummaryDTO(
                    captureId: 301,
                    title: "페이지 카드",
                    summary: "요약",
                    typeCode: .knowledge,
                    thumbnailUrl: nil,
                    isFavorite: false,
                    organizedAt: Date(timeIntervalSince1970: 1_785_000_000)
                )
            ]
        )
        let networkClient = HomeNetworkClientStub(
            response: APIResponse(success: true, data: dto)
        )
        let service = HomeSummaryService(networkClient: networkClient)

        let page = try await service.fetchRecentCaptures(page: 2, size: 20)

        XCTAssertEqual(page.totalCount, 1)
        XCTAssertTrue(page.hasNext)
        XCTAssertEqual(page.cards.map(\.captureID), [301])

        let endpoint = try XCTUnwrap(networkClient.lastEndpoint)
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path, "/api/v1/home/recent-captures")
        XCTAssertEqual(endpoint.authorization, .bearer)
        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: endpoint.queryItems.map { ($0.name, $0.value) }),
            ["page": "2", "size": "20"]
        )
    }

    func testHomeFeatureModelExposesFailureAndRetries() async {
        let expected = HomeSummaryContent(
            recentCards: [],
            favoriteCards: [],
            frequentTypes: [],
            hasAnyCapture: false
        )
        let loader = SequencedHomeSummaryLoader(results: [
            .failure(APIError.offline),
            .success(expected)
        ])
        let model = HomeFeatureModel(summaryLoader: loader)

        await model.loadIfNeeded()
        XCTAssertEqual(model.state, .failed)

        await model.retry()
        XCTAssertEqual(model.state, .loaded(expected))
        XCTAssertEqual(loader.requestCount, 2)
    }

    func testCancelledInitialLoadCanRestartWhenHomeReappears() async {
        let expected = HomeSummaryContent.empty
        let loader = CancellationThenSuccessHomeSummaryLoader(success: expected)
        let model = HomeFeatureModel(summaryLoader: loader)
        let initialLoad = Task {
            await model.loadIfNeeded()
        }

        await loader.waitUntilFirstRequest()
        initialLoad.cancel()
        await initialLoad.value

        XCTAssertEqual(model.state, .idle)

        await model.loadIfNeeded()

        XCTAssertEqual(model.state, .loaded(expected))
        XCTAssertEqual(loader.requestCount, 2)
    }

    func testURLProtocolIntegrationAddsBearerAndDecodesSummary() async throws {
        HomeSummaryURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/home/summary")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer local-access-token")

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.summaryJSON.utf8))
        }

        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        urlSessionConfiguration.protocolClasses = [HomeSummaryURLProtocol.self]
        let rawClient = AlamofireNetworkClient(
            configuration: NetworkConfiguration(baseURL: URL(string: "https://home.test")!),
            urlSessionConfiguration: urlSessionConfiguration
        )
        let authenticatedClient = AuthenticatedNetworkClient(
            networkClient: rawClient,
            accessTokenProvider: { "local-access-token" },
            sessionRefresher: {
                XCTFail("A successful response must not refresh the session")
                throw APIError.transport
            },
            sessionInvalidationHandler: {
                XCTFail("A successful response must not invalidate the session")
            }
        )
        let service = HomeSummaryService(networkClient: authenticatedClient)

        let content = try await service.fetchSummary()

        XCTAssertEqual(content.recentCards.first?.captureID, 101)
        XCTAssertEqual(HomeSummaryURLProtocol.requestCount, 1)
    }

    private static func decodedSummary() throws -> HomeSummaryContent {
        let response = try JSONDecoder.recapAPI.decode(
            APIResponse<HomeSummaryDTO>.self,
            from: Data(Self.summaryJSON.utf8)
        )
        return HomeSummaryContent(dto: try response.requiredData())
    }

    private static func recentCard(in model: HomeFeatureModel) -> CardSnapshot? {
        guard case .loaded(let content) = model.state else { return nil }
        return content.recentCards.first
    }

    func testFavoritesAreSortedByOrganizedAtDescending() throws {
        let response = try JSONDecoder.recapAPI.decode(
            APIResponse<HomeSummaryDTO>.self,
            from: Data(Self.unorderedFavoritesJSON.utf8)
        )

        let content = HomeSummaryContent(dto: try response.requiredData())

        XCTAssertEqual(content.favoriteCards.map(\.captureID), [203, 201, 202, 204])
    }

    /// 같은 정리 시각을 가진 202, 204는 서버 응답 순서를 유지해야 한다.
    private static let unorderedFavoritesJSON = """
    {
      "success": true,
      "data": {
        "recentCaptures": [],
        "favorites": [
          {
            "captureId": 201,
            "title": "중간",
            "summary": "요약",
            "typeCode": "KNOWLEDGE",
            "thumbnailUrl": null,
            "isFavorite": true,
            "organizedAt": "2026-07-22T00:00:00Z"
          },
          {
            "captureId": 202,
            "title": "가장 오래됨",
            "summary": "요약",
            "typeCode": "KNOWLEDGE",
            "thumbnailUrl": null,
            "isFavorite": true,
            "organizedAt": "2026-07-20T00:00:00Z"
          },
          {
            "captureId": 203,
            "title": "가장 최신",
            "summary": "요약",
            "typeCode": "KNOWLEDGE",
            "thumbnailUrl": null,
            "isFavorite": true,
            "organizedAt": "2026-07-24T00:00:00Z"
          },
          {
            "captureId": 204,
            "title": "가장 오래됨 동률",
            "summary": "요약",
            "typeCode": "KNOWLEDGE",
            "thumbnailUrl": null,
            "isFavorite": true,
            "organizedAt": "2026-07-20T00:00:00Z"
          }
        ],
        "topTypes": [],
        "hasAnyCapture": true
      },
      "error": null
    }
    """

    nonisolated private static let summaryJSON = """
    {
      "success": true,
      "data": {
        "recentCaptures": [
          {
            "captureId": 101,
            "title": "최근 카드",
            "summary": "최근 카드 요약",
            "typeCode": "SHOPPING",
            "thumbnailUrl": "https://images.example.com/101.jpg",
            "isFavorite": false,
            "organizedAt": "2026-07-23T01:02:03Z"
          }
        ],
        "favorites": [
          {
            "captureId": 102,
            "title": "즐겨찾기 카드",
            "summary": "즐겨찾기 요약",
            "typeCode": "KNOWLEDGE",
            "thumbnailUrl": "https://images.example.com/102.jpg",
            "isFavorite": true,
            "organizedAt": "2026-07-22T01:02:03Z"
          }
        ],
        "topTypes": [
          {
            "typeCode": "JOB",
            "count": 4,
            "representativeThumbnailUrl": "https://images.example.com/job.jpg"
          }
        ],
        "hasAnyCapture": true
      },
      "error": null
    }
    """
}

private final class HomeNetworkClientStub: NetworkClient {
    private let response: any Sendable
    private let recordedEndpoint = Mutex<APIEndpoint?>(nil)

    init<Response: Sendable>(response: Response) {
        self.response = response
    }

    var lastEndpoint: APIEndpoint? {
        recordedEndpoint.withLock { $0 }
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        recordedEndpoint.withLock { $0 = endpoint }

        guard let typedResponse = response as? Response else {
            throw APIError.decoding
        }
        return typedResponse
    }
}

@MainActor
private final class SequencedHomeSummaryLoader: HomeSummaryLoading {
    private var results: [Result<HomeSummaryContent, Error>]
    private(set) var requestCount = 0

    init(results: [Result<HomeSummaryContent, Error>]) {
        self.results = results
    }

    func fetchSummary() async throws -> HomeSummaryContent {
        requestCount += 1
        guard !results.isEmpty else {
            throw APIError.transport
        }
        return try results.removeFirst().get()
    }
}

@MainActor
private final class CancellationThenSuccessHomeSummaryLoader: HomeSummaryLoading {
    private let success: HomeSummaryContent
    private var firstRequestWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var requestCount = 0

    init(success: HomeSummaryContent) {
        self.success = success
    }

    func fetchSummary() async throws -> HomeSummaryContent {
        requestCount += 1

        if requestCount == 1 {
            firstRequestWaiters.forEach { $0.resume() }
            firstRequestWaiters.removeAll()
            try await Task.sleep(for: .seconds(30))
        }

        return success
    }

    func waitUntilFirstRequest() async {
        guard requestCount == 0 else { return }
        await withCheckedContinuation { continuation in
            firstRequestWaiters.append(continuation)
        }
    }
}

private final class HomeSummaryURLProtocol: URLProtocol {
    /// URL 로딩 스레드에서 병렬로 호출되므로 상태를 통째로 잠금 뒤에 둔다.
    private struct State {
        var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
        var requestCount = 0
    }

    private static let state = Mutex(State())

    static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))? {
        get { state.withLock(\.handler) }
        set { state.withLock { $0.handler = newValue } }
    }

    static var requestCount: Int {
        state.withLock(\.requestCount)
    }

    static func reset() {
        state.withLock { $0 = State() }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let handler = try XCTUnwrap(Self.handler)
            Self.state.withLock { $0.requestCount += 1 }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class HomeCaptureMutatorStub: CaptureMutating {
    struct FavoriteUpdate: Equatable, Sendable {
        let captureID: Int64
        let isFavorite: Bool
    }

    private let favoriteError: (any Error & Sendable)?
    private let storedFavoriteUpdates = Mutex<[FavoriteUpdate]>([])

    init(favoriteError: (any Error & Sendable)? = nil) {
        self.favoriteError = favoriteError
    }

    var favoriteUpdates: [FavoriteUpdate] {
        storedFavoriteUpdates.withLock { $0 }
    }

    func deleteCapture(captureID: Int64) async throws {}
    func deleteCaptures(captureIDs: [Int64]) async throws {}

    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {
        if let favoriteError {
            throw favoriteError
        }
        storedFavoriteUpdates.withLock {
            $0.append(FavoriteUpdate(captureID: captureID, isFavorite: isFavorite))
        }
    }

    func updateCapture(captureID: Int64, draft: CardEditDraft) async throws {}
    func reportCapture(captureID: Int64, reason: CaptureReportReason, detail: String?) async throws {}
}
