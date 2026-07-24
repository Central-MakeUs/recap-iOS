import XCTest
@testable import Recap

@MainActor
final class ArchiveAPITests: XCTestCase {
    override func tearDown() {
        ArchiveURLProtocol.reset()
        super.tearDown()
    }

    func testArchiveHomeCombinesTypesFavoritesAndOther() async throws {
        let client = ArchiveNetworkClientStub()
        let service = ArchiveService(networkClient: client)

        let content = try await service.fetchHome()

        XCTAssertEqual(Set(client.endpoints.map(\.path)), [
            "/api/v1/storage/types",
            "/api/v1/storage/favorites",
            "/api/v1/storage/etc"
        ])
        XCTAssertEqual(content.favoriteCount, 1)
        XCTAssertEqual(content.otherCount, 1)
        XCTAssertEqual(content.summaries.first?.kind, .shopping)
        XCTAssertEqual(content.summaries.first?.previewTitle, "대표 제목")
    }

    func testArchiveHomeFavoriteRefreshRequestsOnlyFavorites() async throws {
        let client = ArchiveNetworkClientStub()
        let service = ArchiveService(networkClient: client)
        let current = ArchiveHomeContent(
            summaries: [CollectionSummary(kind: .shopping, count: 7, previewTitle: "기존 제목")],
            favoriteCount: 99,
            otherCount: 5
        )

        let refreshed = try await service.refreshHome(
            current,
            scopes: [.favorites]
        )

        XCTAssertEqual(client.endpoints.map(\.path), ["/api/v1/storage/favorites"])
        XCTAssertEqual(refreshed.summaries, current.summaries)
        XCTAssertEqual(refreshed.favoriteCount, 1)
        XCTAssertEqual(refreshed.otherCount, current.otherCount)
    }

    func testFavoritesDoesNotSendSortQuery() async throws {
        let client = ArchiveNetworkClientStub()
        let service = ArchiveService(networkClient: client)

        _ = try await service.fetchCards(scope: .favorites, sort: .oldest)

        let endpoint = try XCTUnwrap(client.endpoints.last)
        XCTAssertEqual(endpoint.path, "/api/v1/storage/favorites")
        XCTAssertTrue(endpoint.queryItems.isEmpty)
        XCTAssertEqual(endpoint.authorization, .bearer)
    }

    func testOtherAndTypeDetailSendRequestedSort() async throws {
        let client = ArchiveNetworkClientStub()
        let service = ArchiveService(networkClient: client)

        _ = try await service.fetchCards(scope: .category(.other), sort: .oldest)
        _ = try await service.fetchCards(scope: .category(.shopping), sort: .latest)

        XCTAssertEqual(client.endpoints[0].path, "/api/v1/storage/etc")
        XCTAssertEqual(client.endpoints[0].queryItems, [
            URLQueryItem(name: "sort", value: "oldest")
        ])
        XCTAssertEqual(
            client.endpoints[1].path,
            "/api/v1/storage/types/SHOPPING/captures"
        )
        XCTAssertEqual(client.endpoints[1].queryItems, [
            URLQueryItem(name: "sort", value: "latest")
        ])
    }

    func testArchiveCaptureResponseMapsToInformationCard() async throws {
        let client = ArchiveNetworkClientStub()
        let service = ArchiveService(networkClient: client)

        let cards = try await service.fetchCards(
            scope: .category(.shopping),
            sort: .latest
        )
        let card = try XCTUnwrap(cards.first)

        XCTAssertEqual(card.captureID, 101)
        XCTAssertEqual(card.collection, .shopping)
        XCTAssertEqual(card.category, "쇼핑 · 상품")
        XCTAssertEqual(card.thumbnailURL?.absoluteString, "https://images.example.com/101.jpg")
    }

    func testHomeFeatureModelFailsAndRetriesAllHomeRequests() async {
        let expected = ArchiveHomeContent.empty
        let loader = SequencedArchiveLoader(homeResults: [
            .failure(APIError.offline),
            .success(expected)
        ])
        let model = ArchiveHomeFeatureModel(loader: loader)

        await model.loadIfNeeded()
        XCTAssertEqual(model.state, .failed)

        await model.retry()
        XCTAssertEqual(model.state, .loaded(expected))
        XCTAssertEqual(loader.homeRequestCount, 2)
    }

    func testCancelledArchiveLoadReturnsToIdleAndCanRestart() async {
        let loader = CancellationThenSuccessArchiveLoader()
        let model = ArchiveHomeFeatureModel(loader: loader)
        let initialLoad = Task {
            await model.loadIfNeeded()
        }

        await loader.waitUntilFirstRequest()
        initialLoad.cancel()
        await initialLoad.value

        XCTAssertEqual(model.state, .idle)

        await model.loadIfNeeded()

        XCTAssertEqual(model.state, .loaded(.empty))
        XCTAssertEqual(loader.homeRequestCount, 2)
    }

    func testDetailSortReloadsOnlyForSortableScopes() async {
        let loader = SequencedArchiveLoader(homeResults: [])
        let otherModel = ArchiveDetailFeatureModel(
            scope: .category(.other),
            loader: loader
        )
        let favoritesModel = ArchiveDetailFeatureModel(
            scope: .favorites,
            loader: loader
        )

        await otherModel.loadIfNeeded()
        await otherModel.selectSort(.oldest)
        await favoritesModel.loadIfNeeded()
        await favoritesModel.selectSort(.oldest)

        XCTAssertEqual(
            loader.detailRequests.map(\.sort),
            [.latest, .oldest, .latest]
        )
        XCTAssertEqual(favoritesModel.sort, .latest)
    }

    func testURLProtocolIntegrationAddsBearerAndDecodesArchiveList() async throws {
        ArchiveURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/storage/etc")
            XCTAssertEqual(request.url?.query, "sort=oldest")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer local-access-token"
            )

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.captureListJSON.utf8))
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ArchiveURLProtocol.self]
        let rawClient = AlamofireNetworkClient(
            configuration: NetworkConfiguration(
                baseURL: URL(string: "https://archive.test")!
            ),
            urlSessionConfiguration: configuration
        )
        let authenticatedClient = AuthenticatedNetworkClient(
            networkClient: rawClient,
            accessTokenProvider: { "local-access-token" },
            sessionRefresher: {
                XCTFail("성공 응답에서 refresh를 호출하면 안 됩니다.")
                throw APIError.transport
            },
            sessionInvalidationHandler: {
                XCTFail("성공 응답에서 세션을 삭제하면 안 됩니다.")
            }
        )
        let service = ArchiveService(networkClient: authenticatedClient)

        let cards = try await service.fetchCards(
            scope: .category(.other),
            sort: .oldest
        )

        XCTAssertEqual(cards.first?.captureID, 101)
        XCTAssertEqual(ArchiveURLProtocol.requestCount, 1)
    }

    func testLocalServerStorageEndpointsThroughAuthenticatedClient() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard
            let token = environment["RECAP_LOCAL_API_TOKEN"],
            let baseURLString = environment["RECAP_LOCAL_API_BASE_URL"],
            let baseURL = URL(string: baseURLString)
        else {
            throw XCTSkip("로컬 서버 인증 smoke 환경변수가 없습니다.")
        }

        let rawClient = AlamofireNetworkClient(
            configuration: NetworkConfiguration(baseURL: baseURL)
        )
        let authenticatedClient = AuthenticatedNetworkClient(
            networkClient: rawClient,
            accessTokenProvider: { token },
            sessionRefresher: {
                XCTFail("유효한 로컬 토큰에서 refresh를 호출하면 안 됩니다.")
                throw APIError.transport
            },
            sessionInvalidationHandler: {
                XCTFail("유효한 로컬 토큰에서 세션을 삭제하면 안 됩니다.")
            }
        )
        let service = ArchiveService(networkClient: authenticatedClient)

        let home = try await service.fetchHome()
        let favorites = try await service.fetchCards(
            scope: .favorites,
            sort: .latest
        )
        let other = try await service.fetchCards(
            scope: .category(.other),
            sort: .oldest
        )
        let shopping = try await service.fetchCards(
            scope: .category(.shopping),
            sort: .latest
        )

        XCTAssertEqual(home.favoriteCount, favorites.count)
        XCTAssertEqual(home.otherCount, other.count)
        XCTAssertTrue(shopping.isEmpty)
    }

    nonisolated static let captureListJSON = """
    {
      "success": true,
      "data": {
        "count": 1,
        "items": [
          {
            "captureId": 101,
            "title": "서버 카드",
            "summary": "서버 카드 요약",
            "typeCode": "SHOPPING",
            "thumbnailUrl": "https://images.example.com/101.jpg",
            "isFavorite": true,
            "organizedAt": "2026-07-23T01:02:03Z"
          }
        ]
      },
      "error": null
    }
    """
}

private final class ArchiveNetworkClientStub: NetworkClient, @unchecked Sendable {
    private let lock = NSLock()
    private var storedEndpoints: [APIEndpoint] = []

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

        let data: Data
        switch endpoint.path {
        case "/api/v1/storage/types":
            data = Data(Self.typesJSON.utf8)
        default:
            data = Data(ArchiveAPITests.captureListJSON.utf8)
        }

        return try JSONDecoder.recapAPI.decode(Response.self, from: data)
    }

    private static let typesJSON = """
    {
      "success": true,
      "data": [
        {
          "typeCode": "SHOPPING",
          "count": 1,
          "representativeTitles": ["대표 제목"]
        }
      ],
      "error": null
    }
    """
}

@MainActor
private final class SequencedArchiveLoader: ArchiveLoading {
    private var homeResults: [Result<ArchiveHomeContent, Error>]
    private(set) var homeRequestCount = 0
    private(set) var detailRequests: [(scope: ArchiveDetailScope, sort: ArchiveSort)] = []

    init(homeResults: [Result<ArchiveHomeContent, Error>]) {
        self.homeResults = homeResults
    }

    func fetchHome() async throws -> ArchiveHomeContent {
        homeRequestCount += 1
        guard !homeResults.isEmpty else {
            throw APIError.transport
        }
        return try homeResults.removeFirst().get()
    }

    func fetchCards(
        scope: ArchiveDetailScope,
        sort: ArchiveSort
    ) async throws -> [InformationCard] {
        detailRequests.append((scope, sort))
        return []
    }
}

@MainActor
private final class CancellationThenSuccessArchiveLoader: ArchiveLoading {
    private var firstRequestWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var homeRequestCount = 0

    func fetchHome() async throws -> ArchiveHomeContent {
        homeRequestCount += 1

        if homeRequestCount == 1 {
            firstRequestWaiters.forEach { $0.resume() }
            firstRequestWaiters.removeAll()
            try await Task.sleep(for: .seconds(30))
        }

        return .empty
    }

    func fetchCards(
        scope: ArchiveDetailScope,
        sort: ArchiveSort
    ) async throws -> [InformationCard] {
        []
    }

    func waitUntilFirstRequest() async {
        guard homeRequestCount == 0 else { return }
        await withCheckedContinuation { continuation in
            firstRequestWaiters.append(continuation)
        }
    }
}

private final class ArchiveURLProtocol: URLProtocol, @unchecked Sendable {
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

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            let handler = try Self.lock.withLock {
                Self.storedRequestCount += 1
                return try XCTUnwrap(Self.storedHandler)
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
