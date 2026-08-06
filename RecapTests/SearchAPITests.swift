import Synchronization
import XCTest
@testable import Recap

@MainActor
final class SearchAPITests: XCTestCase {
    override func tearDown() {
        SearchURLProtocol.reset()
        super.tearDown()
    }

    func testSearchServiceSendsAllScopeWithBearerAuthorization() async throws {
        let client = SearchNetworkClientStub(response: SearchResponseDTO.fixture())
        let service = SearchService(networkClient: client)

        _ = try await service.search(
            query: "파스타 레시피",
            scope: .all,
            page: 0,
            size: 20
        )

        let endpoint = try XCTUnwrap(client.endpoints.first)
        XCTAssertEqual(endpoint.path, "/api/v1/search")
        XCTAssertEqual(endpoint.authorization, .bearer)
        let query: [String: String] = Dictionary(
            uniqueKeysWithValues: endpoint.queryItems.compactMap {
                guard let value = $0.value else { return nil }
                return ($0.name, value)
            }
        )
        XCTAssertEqual(
            query,
            [
                "q": "파스타 레시피",
                "scope": "ALL",
                "page": "0",
                "size": "20"
            ]
        )
    }

    func testTypeScopeAddsTypeCode() async throws {
        let client = SearchNetworkClientStub(response: SearchResponseDTO.fixture())
        let service = SearchService(networkClient: client)

        _ = try await service.search(
            query: "채용",
            scope: .type(.career),
            page: 2,
            size: 10
        )

        let queryItems = try XCTUnwrap(client.endpoints.first?.queryItems)
        let query: [String: String] = Dictionary(
            uniqueKeysWithValues: queryItems.compactMap {
                guard let value = $0.value else { return nil }
                return ($0.name, value)
            }
        )

        XCTAssertEqual(query["scope"], "TYPE")
        XCTAssertEqual(query["typeCode"], "JOB")
        XCTAssertEqual(query["page"], "2")
        XCTAssertEqual(query["size"], "10")
    }

    func testArchiveDetailScopeUsesMatchingServerSearchScope() {
        XCTAssertEqual(
            ArchiveDetailScope.favorites.searchScope,
            SearchScope.favorites
        )
        XCTAssertEqual(
            ArchiveDetailScope.category(.other).searchScope,
            SearchScope.other
        )
        XCTAssertEqual(
            ArchiveDetailScope.category(.career).searchScope,
            SearchScope.type(.career)
        )
    }

    func testSearchResultUsesOCRExcerptInExistingSummarySlot() throws {
        let dto = SearchResultDTO.fixture(
            titleHighlighted: "파스타 레시피",
            summaryHighlighted: "기존 요약",
            ocrExcerptHighlighted: "…재료는 <mark>토마토</mark>와 면…"
        )

        let result = SearchResult(dto: dto)

        XCTAssertEqual(result.card.summary, "…재료는 토마토와 면…")
        XCTAssertEqual(
            result.summary.segments,
            [
                SearchHighlightSegment(text: "…재료는 ", isHighlighted: false),
                SearchHighlightSegment(text: "토마토", isHighlighted: true),
                SearchHighlightSegment(text: "와 면…", isHighlighted: false)
            ]
        )
    }

    func testHighlightParserOnlyInterpretsExactMarkTags() {
        let highlighted = SearchHighlightedString(
            serverValue: "앞<mark>검색어</mark><script>뒤"
        )

        XCTAssertEqual(highlighted.plainText, "앞검색어<script>뒤")
        XCTAssertEqual(
            highlighted.segments,
            [
                SearchHighlightSegment(text: "앞", isHighlighted: false),
                SearchHighlightSegment(text: "검색어", isHighlighted: true),
                SearchHighlightSegment(text: "<script>뒤", isHighlighted: false)
            ]
        )
    }

    func testRapidQueryChangesRequestOnlyLatestQuery() async {
        let loader = RecordingSearchLoader()
        let model = SearchFeatureModel(loader: loader)

        let firstSearch = Task {
            await model.search(query: "첫 검색", debounce: .milliseconds(80))
        }
        try? await Task.sleep(for: .milliseconds(10))
        let secondSearch = Task {
            await model.search(query: "최종 검색", debounce: .milliseconds(10))
        }

        await firstSearch.value
        await secondSearch.value

        XCTAssertEqual(loader.requests.map(\.query), ["최종 검색"])
    }

    func testSameNormalizedQueryDoesNotRequestAgain() async {
        let loader = RecordingSearchLoader()
        let model = SearchFeatureModel(loader: loader)

        await model.search(query: "  파스타   레시피  ", debounce: .milliseconds(0))
        await model.search(query: "파스타 레시피", debounce: .milliseconds(0))

        XCTAssertEqual(loader.requests.map(\.query), ["파스타 레시피"])
    }

    func testFavoriteInvalidationRefreshesCurrentQuery() async throws {
        let initialResult = SearchResult(dto: .fixture(isFavorite: false))
        let refreshedResult = SearchResult(dto: .fixture(isFavorite: true))
        let loader = RecordingSearchLoader(pages: [
            SearchPage(count: 1, hasNext: false, items: [initialResult]),
            SearchPage(count: 1, hasNext: false, items: [refreshedResult])
        ])
        let model = SearchFeatureModel(loader: loader)
        let invalidationCenter = CardDataInvalidationCenter()

        await model.search(query: "파스타", debounce: .milliseconds(0))
        invalidationCenter.invalidate(.favoriteChanged)
        await model.refreshCurrentQuery()

        XCTAssertEqual(invalidationCenter.searchRevision, 1)
        XCTAssertEqual(loader.requests.map(\.query), ["파스타", "파스타"])
        guard case .loaded(let content) = model.state else {
            return XCTFail("검색 결과가 loaded 상태여야 합니다.")
        }
        XCTAssertTrue(try XCTUnwrap(content.results.first).card.isFavorite)
    }

    func testRepeatedLastRowAppearanceLoadsNextPageOnce() async throws {
        let firstResult = SearchResult(dto: .fixture(captureId: 1))
        let secondResult = SearchResult(dto: .fixture(captureId: 2))
        let loader = RecordingSearchLoader(pages: [
            SearchPage(count: 2, hasNext: true, items: [firstResult]),
            SearchPage(count: 2, hasNext: false, items: [secondResult])
        ])
        let model = SearchFeatureModel(loader: loader, pageSize: 1)

        await model.search(query: "검색", debounce: .milliseconds(0))
        async let firstLoad: Void = model.loadNextPageIfNeeded(after: firstResult.id)
        async let secondLoad: Void = model.loadNextPageIfNeeded(after: firstResult.id)
        _ = await (firstLoad, secondLoad)

        XCTAssertEqual(loader.requests.map(\.page), [0, 1])
        guard case .loaded(let content) = model.state else {
            return XCTFail("검색 결과가 loaded 상태여야 합니다.")
        }
        XCTAssertEqual(content.results.map(\.captureID), [1, 2])
    }

    func testURLProtocolIntegrationAddsBearerAndDecodesSearchResponse() async throws {
        SearchURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/search")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer local-access-token"
            )
            let queryItems = URLComponents(
                url: try XCTUnwrap(request.url),
                resolvingAgainstBaseURL: false
            )?.queryItems
            XCTAssertEqual(queryItems?.first(where: { $0.name == "q" })?.value, "파스타")
            XCTAssertEqual(queryItems?.first(where: { $0.name == "scope" })?.value, "ALL")

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.searchJSON.utf8))
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SearchURLProtocol.self]
        let rawClient = AlamofireNetworkClient(
            configuration: NetworkConfiguration(
                baseURL: URL(string: "https://search.test")!
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
        let service = SearchService(networkClient: authenticatedClient)

        let page = try await service.search(
            query: "파스타",
            scope: .all,
            page: 0,
            size: 20
        )

        XCTAssertEqual(page.count, 1)
        XCTAssertEqual(page.items.first?.captureID, 101)
        XCTAssertEqual(SearchURLProtocol.requestCount, 1)
    }

    func testLocalServerSearchThroughAuthenticatedClient() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard
            let token = environment["RECAP_LOCAL_API_TOKEN"],
            let baseURLString = environment["RECAP_LOCAL_API_BASE_URL"],
            let baseURL = URL(string: baseURLString)
        else {
            throw XCTSkip("로컬 서버 검색 smoke 환경변수가 없습니다.")
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
        let service = SearchService(networkClient: authenticatedClient)

        _ = try await service.search(
            query: environment["RECAP_LOCAL_SEARCH_QUERY"] ?? "테스트",
            scope: .all,
            page: 0,
            size: 20
        )
    }

    nonisolated private static let searchJSON = """
    {
      "success": true,
      "data": {
        "count": 1,
        "hasNext": false,
        "items": [
          {
            "captureId": 101,
            "typeCode": "KNOWLEDGE",
            "thumbnailUrl": "https://images.example.com/101.jpg",
            "titleHighlighted": "<mark>파스타</mark> 레시피",
            "summaryHighlighted": "집에서 만드는 파스타",
            "ocrExcerptHighlighted": null,
            "isFavorite": true,
            "organizedAt": "2026-07-23T01:02:03Z"
          }
        ]
      },
      "error": null
    }
    """
}

private extension SearchResponseDTO {
    static func fixture(
        count: Int = 0,
        hasNext: Bool = false,
        items: [SearchResultDTO] = []
    ) -> APIResponse<SearchResponseDTO> {
        APIResponse(
            success: true,
            data: SearchResponseDTO(count: count, hasNext: hasNext, items: items)
        )
    }
}

private extension SearchResultDTO {
    static func fixture(
        captureId: Int64 = 101,
        titleHighlighted: String = "<mark>검색</mark> 결과",
        summaryHighlighted: String = "검색 결과 요약",
        ocrExcerptHighlighted: String? = nil,
        isFavorite: Bool = false
    ) -> SearchResultDTO {
        SearchResultDTO(
            captureId: captureId,
            typeCode: .knowledge,
            thumbnailUrl: URL(string: "https://images.example.com/\(captureId).jpg"),
            titleHighlighted: titleHighlighted,
            summaryHighlighted: summaryHighlighted,
            ocrExcerptHighlighted: ocrExcerptHighlighted,
            isFavorite: isFavorite,
            organizedAt: Date(timeIntervalSince1970: 1_753_232_523)
        )
    }
}

private final class SearchNetworkClientStub: NetworkClient, @unchecked Sendable {
    private let response: Any
    private(set) var endpoints: [APIEndpoint] = []

    init<Response>(response: Response) {
        self.response = response
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        endpoints.append(endpoint)
        guard let response = response as? Response else {
            throw APIError.decoding
        }
        return response
    }
}

@MainActor
private final class RecordingSearchLoader: SearchLoading {
    struct Request: Equatable {
        let query: String
        let scope: SearchScope
        let page: Int
        let size: Int
    }

    private var pages: [SearchPage]
    private(set) var requests: [Request] = []

    init(pages: [SearchPage] = [SearchPage(count: 0, hasNext: false, items: [])]) {
        self.pages = pages
    }

    func search(
        query: String,
        scope: SearchScope,
        page: Int,
        size: Int
    ) async throws -> SearchPage {
        requests.append(Request(query: query, scope: scope, page: page, size: size))
        guard !pages.isEmpty else {
            return SearchPage(count: 0, hasNext: false, items: [])
        }
        return pages.removeFirst()
    }
}

private final class SearchURLProtocol: URLProtocol {
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
