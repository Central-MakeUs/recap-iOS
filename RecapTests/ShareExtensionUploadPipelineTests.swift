import Synchronization
import XCTest
@testable import Recap

/// 공유 확장 업로드 파이프라인의 취소 동작을 검증한다.
/// 네트워크는 `ShareUploadStubURLProtocol`이 전부 가로채므로 실제 요청은 나가지 않는다.
@MainActor
final class ShareExtensionUploadPipelineTests: XCTestCase {
    /// `setUp`/`tearDown` 오버라이드는 nonisolated라 프로퍼티를 건드리지 않고,
    /// 매 테스트가 자기 파이프라인을 만든다.
    private func makePipeline() -> ShareExtensionUploadPipeline {
        ShareUploadStubURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ShareUploadStubURLProtocol.self]

        return ShareExtensionUploadPipeline(
            baseURL: URL(string: "https://example.invalid")!,
            session: URLSession(configuration: configuration),
            tokenStore: ShareUploadStubTokenStore(),
            pollingInterval: .milliseconds(10),
            maximumPollingAttempts: 1_000
        )
    }

    /// 정리 도중 취소하면 서버 배치도 취소해야 한다.
    /// 회귀 대상: `organize`가 중단되며 batchID를 비워버려 취소 요청이 누락되던 문제.
    func testCancellingOrganizeSendsCancelRequestForCurrentBatch() async throws {
        let pipeline = makePipeline()
        let organizeStarted = expectation(description: "서버가 batchID를 발급했다")
        ShareUploadStubURLProtocol.onOrganizeIssued { organizeStarted.fulfill() }

        let organizing = Task {
            try await pipeline.organize(images: [Self.imageData]) { _ in }
        }

        await fulfillment(of: [organizeStarted], timeout: 5)
        // 폴링이 최소 한 번 돌아 취소 가능한 상태임을 확실히 한다.
        try await Task.sleep(for: .milliseconds(50))

        await pipeline.cancelCurrentProcess()
        organizing.cancel()
        _ = try? await organizing.value

        XCTAssertTrue(
            ShareUploadStubURLProtocol.recordedRequests.contains {
                $0.method == "POST"
                    && $0.path == "/api/v1/captures/organize/\(Self.batchID)/cancel"
            },
            "서버 정리 배치 취소 요청이 없습니다. 보낸 요청: \(ShareUploadStubURLProtocol.recordedRequests)"
        )
    }

    /// 취소 순서가 뒤바뀌어도 배치가 남지 않아야 한다.
    /// task를 먼저 취소한 뒤 취소 요청을 보내는 경로를 재현한다.
    func testCancelSurvivesTaskCancellationHappeningFirst() async throws {
        let pipeline = makePipeline()
        let organizeStarted = expectation(description: "서버가 batchID를 발급했다")
        ShareUploadStubURLProtocol.onOrganizeIssued { organizeStarted.fulfill() }

        let organizing = Task {
            try await pipeline.organize(images: [Self.imageData]) { _ in }
        }

        await fulfillment(of: [organizeStarted], timeout: 5)
        try await Task.sleep(for: .milliseconds(50))

        organizing.cancel()
        _ = try? await organizing.value
        await pipeline.cancelCurrentProcess()

        XCTAssertTrue(
            ShareUploadStubURLProtocol.recordedRequests.contains {
                $0.method == "POST"
                    && $0.path == "/api/v1/captures/organize/\(Self.batchID)/cancel"
            },
            "task 취소가 먼저 일어나면 batchID가 사라져 취소 요청이 누락됩니다. "
                + "보낸 요청: \(ShareUploadStubURLProtocol.recordedRequests)"
        )
    }

    /// 정상 완료한 배치는 취소 요청을 보내지 않아야 한다.
    func testCompletedOrganizeDoesNotSendCancelRequest() async throws {
        let pipeline = makePipeline()
        ShareUploadStubURLProtocol.completeOrganizeImmediately()

        let result = try await pipeline.organize(images: [Self.imageData]) { _ in }
        XCTAssertEqual(result.batchID, Self.batchID)

        await pipeline.cancelCurrentProcess()

        XCTAssertFalse(
            ShareUploadStubURLProtocol.recordedRequests.contains { $0.path.hasSuffix("/cancel") },
            "완료된 배치에 취소 요청을 보내면 안 됩니다."
        )
    }

    static var batchID: Int64 { ShareUploadStubURLProtocol.batchID }
    private static let imageData = Data([0xFF, 0xD8, 0xFF, 0xD9])
}

// MARK: - 스텁

private struct ShareUploadStubTokenStore: ShareTokenStoring {
    func load() throws -> ShareServerTokenRecord {
        ShareServerTokenRecord(
            accessToken: "access",
            refreshToken: "refresh",
            accessTokenExpiresAt: .distantFuture
        )
    }

    func save(_ record: ShareServerTokenRecord) throws {}
}

/// 나가는 요청을 기록하고 미리 정한 응답을 돌려준다. 소켓은 열리지 않는다.
private final class ShareUploadStubURLProtocol: URLProtocol {
    struct RecordedRequest: CustomStringConvertible {
        let method: String
        let path: String

        var description: String { "\(method) \(path)" }
    }

    /// 스텁이 발급하는 고정 batchID.
    static let batchID: Int64 = 4242

    /// 테스트 스레드와 URL 로딩 스레드가 함께 건드리므로 전부 잠금 뒤에 둔다.
    private struct State {
        var recorded: [RecordedRequest] = []
        var onOrganizeIssued: (@Sendable () -> Void)?
        var organizeCompletesImmediately = false
    }

    private static let state = Mutex(State())

    static var recordedRequests: [RecordedRequest] {
        state.withLock(\.recorded)
    }

    /// batchID가 발급된 직후 호출된다.
    static func onOrganizeIssued(_ handler: @escaping @Sendable () -> Void) {
        state.withLock { $0.onOrganizeIssued = handler }
    }

    /// true면 organize 응답이 곧바로 completed로 온다.
    static func completeOrganizeImmediately() {
        state.withLock { $0.organizeCompletesImmediately = true }
    }

    static func reset() {
        state.withLock { $0 = State() }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let path = url.path
        let method = request.httpMethod ?? "GET"
        Self.state.withLock {
            $0.recorded.append(RecordedRequest(method: method, path: path))
        }

        let body = Self.responseBody(path: path, method: method)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)

        if path.hasSuffix("/captures/organize"), method == "POST" {
            Self.state.withLock(\.onOrganizeIssued)?()
        }
    }

    private static func responseBody(path: String, method: String) -> Data {
        let batchID = Self.batchID

        if path.hasSuffix("/captures/upload-urls") {
            return json("""
            {"success":true,"data":{"uploads":[
              {"uploadUrl":"https://example.invalid/put/0","imageKey":"key-0"}
            ]}}
            """)
        }

        if path.hasSuffix("/captures/organize"), method == "POST" {
            let completed = state.withLock(\.organizeCompletesImmediately)
            let status = completed ? "COMPLETED" : "PROCESSING"
            return json("""
            {"success":true,"data":{
              "batchId":\(batchID),"status":"\(status)","totalCount":1
            }}
            """)
        }

        if path.hasSuffix("/status") {
            return json("""
            {"success":true,"data":{
              "batchId":\(batchID),"status":"PROCESSING",
              "totalCount":1,"successCount":0,"failCount":0
            }}
            """)
        }

        // 프리사인 PUT 업로드와 취소 요청은 본문이 없다.
        return Data()
    }

    private static func json(_ string: String) -> Data {
        Data(string.utf8)
    }
}
