import Synchronization
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
        XCTAssertEqual(content.summaries.first?.previewTitle, "최근 제목 · 이전 제목")
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

    func testArchiveStorageTypeWithoutRepresentativeTitlesUsesEmptyPreviewTitle() {
        let dto = ArchiveStorageTypeDTO(
            typeCode: .shopping,
            count: 0,
            representativeTitles: []
        )

        XCTAssertEqual(CollectionSummary(archiveDTO: dto).previewTitle, "")
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

    func testArchiveCaptureResponseMapsToCardSnapshot() async throws {
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

    func testCategoryDetailSortReloadsFromServer() async {
        let loader = SequencedArchiveLoader(homeResults: [])
        let otherModel = ArchiveDetailFeatureModel(
            scope: .category(.other),
            loader: loader,
            cardStore: CardStore(captureMutator: CaptureMutatorStub())
        )

        await otherModel.loadIfNeeded()
        await otherModel.selectSort(.oldest)

        XCTAssertEqual(
            loader.detailRequests.map(\.sort),
            [.latest, .oldest]
        )
        XCTAssertEqual(otherModel.sort, .oldest)
    }

    func testFavoritesSortsLocallyByOrganizedDate() async {
        let older = Self.card(captureID: 101,
            organizedAt: Date(timeIntervalSince1970: 100)
        )
        let newer = Self.card(captureID: 102,
            organizedAt: Date(timeIntervalSince1970: 200)
        )
        let loader = SequencedArchiveLoader(
            homeResults: [],
            detailCards: [older, newer]
        )
        let model = ArchiveDetailFeatureModel(
            scope: .favorites,
            loader: loader,
            cardStore: CardStore(captureMutator: CaptureMutatorStub())
        )

        await model.loadIfNeeded()
        XCTAssertEqual(model.state, .loaded([newer, older]))

        await model.selectSort(.oldest)

        XCTAssertEqual(model.state, .loaded([older, newer]))
        XCTAssertEqual(model.sort, .oldest)
        XCTAssertEqual(loader.detailRequests.map(\.sort), [.latest])
    }

    func testDetailSelectionDeletionCallsAPIAndRemovesDeletedCards() async throws {
        let cards = [
            Self.card(captureID: 101),
            Self.card(captureID: 102),
            Self.card(captureID: 103)
        ]
        let loader = SequencedArchiveLoader(
            homeResults: [],
            detailCards: cards
        )
        let mutator = CaptureMutatorStub()
        let invalidationCenter = CardDataInvalidationCenter()
        let store = CardStore(
            captureMutator: mutator,
            invalidationCenter: invalidationCenter
        )
        let model = ArchiveDetailFeatureModel(
            scope: .category(.shopping),
            loader: loader,
            cardStore: store
        )

        await model.loadIfNeeded()
        try await model.deleteCards(ids: [cards[0].id, cards[1].id])

        XCTAssertEqual(mutator.deletedCaptureIDs, [101, 102])
        XCTAssertEqual(model.state, .loaded([cards[2]]))
        XCTAssertNil(store.card(withCaptureID: 101), "지운 카드는 스토어에서도 내려야 한다")
        XCTAssertNil(store.card(withCaptureID: 102))
        XCTAssertNotNil(store.card(withCaptureID: 103))
        XCTAssertEqual(invalidationCenter.homeRevision, 1)
        XCTAssertEqual(invalidationCenter.archiveDetailRevision, 1)
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

    nonisolated private static func card(
        captureID: Int64,
        organizedAt: Date? = nil
    ) -> CardSnapshot {
        CardSnapshot(
            captureID: captureID,
            title: "카드 \(captureID)",
            summary: "요약",
            collection: .shopping,
            organizedAt: organizedAt,
            location: "",
            businessHours: "",
            category: "쇼핑 · 상품",
            confirmationLabel: nil,
            memo: "",
            tags: [],
            isFavorite: false
        )
    }
}

private final class ArchiveNetworkClientStub: NetworkClient {
    private let storedEndpoints = Mutex<[APIEndpoint]>([])

    var endpoints: [APIEndpoint] {
        storedEndpoints.withLock { $0 }
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        storedEndpoints.withLock { $0.append(endpoint) }

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
          "representativeTitles": ["최근 제목", "이전 제목", "제외할 제목"]
        }
      ],
      "error": null
    }
    """
}

@MainActor
private final class SequencedArchiveLoader: ArchiveLoading {
    private var homeResults: [Result<ArchiveHomeContent, Error>]
    private let detailCards: [CardSnapshot]
    private(set) var homeRequestCount = 0
    private(set) var detailRequests: [(scope: ArchiveDetailScope, sort: ArchiveSort)] = []

    init(
        homeResults: [Result<ArchiveHomeContent, Error>],
        detailCards: [CardSnapshot] = []
    ) {
        self.homeResults = homeResults
        self.detailCards = detailCards
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
    ) async throws -> [CardSnapshot] {
        detailRequests.append((scope, sort))
        return detailCards
    }
}

private final class CaptureMutatorStub: CaptureMutating {
    struct FavoriteUpdate: Equatable, Sendable {
        let captureID: Int64
        let isFavorite: Bool
    }

    private struct State {
        var deletedCaptureIDs: [Int64] = []
        var favoriteUpdates: [FavoriteUpdate] = []
    }

    private let state = Mutex(State())

    var deletedCaptureIDs: [Int64] {
        state.withLock(\.deletedCaptureIDs)
    }

    var favoriteUpdates: [FavoriteUpdate] {
        state.withLock(\.favoriteUpdates)
    }

    func deleteCapture(captureID: Int64) async throws {
        state.withLock { $0.deletedCaptureIDs.append(captureID) }
    }

    func deleteCaptures(captureIDs: [Int64]) async throws {
        state.withLock { $0.deletedCaptureIDs.append(contentsOf: captureIDs) }
    }

    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {
        state.withLock {
            $0.favoriteUpdates.append(
                FavoriteUpdate(captureID: captureID, isFavorite: isFavorite)
            )
        }
    }


    func updateCapture(captureID: Int64, draft: CardEditDraft) async throws {}
    func reportCapture(captureID: Int64, reason: CaptureReportReason, detail: String?) async throws {}
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
    ) async throws -> [CardSnapshot] {
        []
    }

    func waitUntilFirstRequest() async {
        guard homeRequestCount == 0 else { return }
        await withCheckedContinuation { continuation in
            firstRequestWaiters.append(continuation)
        }
    }
}

private final class ArchiveURLProtocol: URLProtocol {
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

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            let handler = try Self.state.withLock { state in
                state.requestCount += 1
                return try XCTUnwrap(state.handler)
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
