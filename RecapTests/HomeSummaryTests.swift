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

    private static let summaryJSON = """
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

private final class HomeNetworkClientStub: NetworkClient, @unchecked Sendable {
    private let lock = NSLock()
    private let response: Any
    private var endpoint: APIEndpoint?

    init<Response>(response: Response) {
        self.response = response
    }

    var lastEndpoint: APIEndpoint? {
        lock.withLock { endpoint }
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        lock.withLock {
            self.endpoint = endpoint
        }

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

private final class HomeSummaryURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private static var storedHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    private static var storedRequestCount = 0

    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get { lock.withLock { storedHandler } }
        set { lock.withLock { storedHandler = newValue } }
    }

    static var requestCount: Int {
        lock.withLock { storedRequestCount }
    }

    static func reset() {
        lock.withLock {
            storedHandler = nil
            storedRequestCount = 0
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let handler = try XCTUnwrap(Self.handler)
            Self.lock.withLock {
                Self.storedRequestCount += 1
            }
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
