import XCTest
@testable import Recap

final class CaptureLifecycleServiceTests: XCTestCase {
    func testCaptureServiceBuildsBackendContractEndpoints() async throws {
        let client = CaptureNetworkClientStub()
        let service = CaptureService(networkClient: client)

        _ = try await service.issueUploadURLs(count: 2)
        _ = try await service.organize(imageKeys: ["a", "b"])
        _ = try await service.organizeStatus(batchID: 7)
        try await service.cancelOrganize(batchID: 7)
        _ = try await service.pendingOrganizeResult()
        try await service.acknowledgeOrganizeResult(batchID: 7)
        _ = try await service.captureDetail(captureID: 11)
        try await service.updateFavorite(captureID: 11, isFavorite: true)
        try await service.deleteCapture(captureID: 11)

        XCTAssertEqual(client.endpoints.map(\.path), [
            "/api/v1/captures/upload-urls",
            "/api/v1/captures/organize",
            "/api/v1/captures/organize/7/status",
            "/api/v1/captures/organize/7/cancel",
            "/api/v1/captures/organize/pending-result",
            "/api/v1/captures/organize/7/ack",
            "/api/v1/captures/11",
            "/api/v1/captures/11/favorite",
            "/api/v1/captures/11"
        ])
        XCTAssertTrue(client.endpoints.allSatisfy { $0.authorization == .bearer })
        XCTAssertEqual(client.endpoints.last?.method.rawValue, "DELETE")

        let uploadBody = try jsonBody(from: client.endpoints[0])
        XCTAssertEqual(uploadBody["count"] as? Int, 2)

        let organizeBody = try jsonBody(from: client.endpoints[1])
        XCTAssertEqual(organizeBody["imageKeys"] as? [String], ["a", "b"])

        let favoriteBody = try jsonBody(from: client.endpoints[7])
        XCTAssertEqual(favoriteBody["isFavorite"] as? Bool, true)
    }

    func testPresignedUploadUsesPutWithoutAuthorizationHeader() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PresignedUploadURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let uploader = URLSessionPresignedImageUploader(session: session)
        let body = Data([0x01, 0x02, 0x03])

        try await uploader.upload(body, to: URL(string: "https://s3.test/upload")!)

        let request = try XCTUnwrap(PresignedUploadURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "image/jpeg")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(PresignedUploadURLProtocol.lastBody, body)
    }

    func testPipelineUploadsEveryImageBeforeOrganizeAndPollsToTerminalStatus() async throws {
        let service = CaptureServiceStub(
            uploadItems: [
                UploadItemDTO(imageKey: "first", uploadUrl: URL(string: "https://upload.test/1")!),
                UploadItemDTO(imageKey: "second", uploadUrl: URL(string: "https://upload.test/2")!)
            ],
            statusResults: [
                OrganizeStatusResponseDTO(
                    batchId: 9,
                    status: .processing,
                    totalCount: 2,
                    successCount: 0,
                    failCount: 0
                ),
                OrganizeStatusResponseDTO(
                    batchId: 9,
                    status: .completed,
                    totalCount: 2,
                    successCount: 2,
                    failCount: 0
                )
            ]
        )
        let uploader = ImageUploaderStub()
        let pipeline = CardCreationPipeline(
            captureService: service,
            imageUploader: uploader,
            pollingInterval: .milliseconds(1),
            maximumPollingAttempts: 3
        )
        let progressRecorder = await MainActor.run {
            CardCreationProgressRecorder()
        }

        let result = try await pipeline.process(
            images: [Data([1]), Data([2])],
            progress: { update in
                progressRecorder.values.append(update.fractionCompleted)
            }
        )
        let progressValues = await MainActor.run {
            progressRecorder.values
        }

        XCTAssertEqual(result.status, .completed)
        XCTAssertEqual(progressValues.last, 1)
        XCTAssertEqual(progressValues, progressValues.sorted())
        XCTAssertEqual(Set(uploader.uploadedURLs.map(\.absoluteString)), [
            "https://upload.test/1",
            "https://upload.test/2"
        ])
        XCTAssertEqual(service.organizedImageKeys, ["first", "second"])
        XCTAssertEqual(service.statusRequestCount, 2)
        XCTAssertEqual(service.acknowledgedBatchIDs, [9])
    }

    func testPipelineRejectsUploadCountMismatchBeforeUploading() async {
        let service = CaptureServiceStub(
            uploadItems: [
                UploadItemDTO(imageKey: "only", uploadUrl: URL(string: "https://upload.test/1")!)
            ],
            statusResults: []
        )
        let uploader = ImageUploaderStub()
        let pipeline = CardCreationPipeline(
            captureService: service,
            imageUploader: uploader
        )

        do {
            _ = try await pipeline.process(images: [Data([1]), Data([2])])
            XCTFail("업로드 개수 불일치는 실패해야 합니다.")
        } catch {
            XCTAssertEqual(error as? CaptureLifecycleError, .uploadCountMismatch)
        }

        XCTAssertTrue(uploader.uploadedURLs.isEmpty)
        XCTAssertTrue(service.organizedImageKeys.isEmpty)
    }

    func testPipelineDoesNotOrganizeWhenAnyUploadFails() async {
        let service = CaptureServiceStub(
            uploadItems: [
                UploadItemDTO(imageKey: "first", uploadUrl: URL(string: "https://upload.test/1")!),
                UploadItemDTO(imageKey: "second", uploadUrl: URL(string: "https://upload.test/2")!)
            ],
            statusResults: []
        )
        let pipeline = CardCreationPipeline(
            captureService: service,
            imageUploader: FailingImageUploader()
        )

        do {
            _ = try await pipeline.process(images: [Data([1]), Data([2])])
            XCTFail("일부 업로드가 실패하면 정리를 시작하면 안 됩니다.")
        } catch {}

        XCTAssertTrue(service.organizedImageKeys.isEmpty)
    }

    func testPipelineTimesOutWhenStatusNeverBecomesTerminal() async {
        let service = CaptureServiceStub(
            uploadItems: [
                UploadItemDTO(imageKey: "first", uploadUrl: URL(string: "https://upload.test/1")!)
            ],
            statusResults: [
                OrganizeStatusResponseDTO(
                    batchId: 9,
                    status: .processing,
                    totalCount: 1,
                    successCount: 0,
                    failCount: 0
                )
            ]
        )
        let pipeline = CardCreationPipeline(
            captureService: service,
            imageUploader: ImageUploaderStub(),
            pollingInterval: .milliseconds(1),
            maximumPollingAttempts: 1
        )

        do {
            _ = try await pipeline.process(images: [Data([1])])
            XCTFail("최대 polling 횟수를 넘기면 실패해야 합니다.")
        } catch {
            XCTAssertEqual(error as? CaptureLifecycleError, .pollingTimedOut)
        }

        XCTAssertTrue(service.acknowledgedBatchIDs.isEmpty)
    }

    func testLocalServerCaptureLifecycleThroughAuthenticatedClient() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard
            let token = environment["RECAP_LOCAL_API_TOKEN"],
            let baseURLString = environment["RECAP_LOCAL_API_BASE_URL"],
            let baseURL = URL(string: baseURLString),
            let captureIDString = environment["RECAP_LOCAL_CAPTURE_ID"],
            let captureID = Int64(captureIDString),
            let completedBatchIDString = environment["RECAP_LOCAL_COMPLETED_BATCH_ID"],
            let completedBatchID = Int64(completedBatchIDString),
            let processingBatchIDString = environment["RECAP_LOCAL_PROCESSING_BATCH_ID"],
            let processingBatchID = Int64(processingBatchIDString)
        else {
            throw XCTSkip("로컬 정보카드 API smoke 환경변수가 없습니다.")
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
        let service = CaptureService(networkClient: authenticatedClient)

        let uploadItems = try await service.issueUploadURLs(count: 2)
        XCTAssertEqual(uploadItems.count, 2)

        let detail = try await service.captureDetail(captureID: captureID)
        XCTAssertEqual(detail.captureID, captureID)

        try await service.updateFavorite(captureID: captureID, isFavorite: true)
        let favoriteDetail = try await service.captureDetail(captureID: captureID)
        XCTAssertTrue(favoriteDetail.isFavorite)

        let completed = try await service.organizeStatus(batchID: completedBatchID)
        let pendingResult = try await service.pendingOrganizeResult()
        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(pendingResult?.batchId, completedBatchID)

        try await service.acknowledgeOrganizeResult(batchID: completedBatchID)
        let pendingResultAfterAcknowledgement = try await service.pendingOrganizeResult()
        XCTAssertNil(pendingResultAfterAcknowledgement)

        try await service.cancelOrganize(batchID: processingBatchID)
        let cancelled = try await service.organizeStatus(batchID: processingBatchID)
        XCTAssertEqual(cancelled.status, .cancelled)
    }

    private func jsonBody(from endpoint: APIEndpoint) throws -> [String: Any] {
        guard case let .json(data) = endpoint.body else {
            throw APIError.malformedRequest
        }
        return try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
    }
}

@MainActor
private final class CardCreationProgressRecorder {
    var values: [Double] = []
}

@MainActor
final class CaptureDetailFeatureModelTests: XCTestCase {
    func testFavoriteFailureRollsBackOptimisticState() async {
        let service = FailingFavoriteCaptureService()
        let invalidationCenter = CardDataInvalidationCenter()
        let model = CaptureDetailFeatureModel(
            card: Self.card(isFavorite: false),
            captureService: service,
            invalidationCenter: invalidationCenter
        )

        do {
            _ = try await model.toggleFavorite()
            XCTFail("서버 실패는 호출자에게 전달되어야 합니다.")
        } catch {}

        XCTAssertFalse(model.card.isFavorite)
        XCTAssertEqual(invalidationCenter.homeRevision, 0)
        XCTAssertEqual(invalidationCenter.archiveHomeRevision, ArchiveHomeRevision())
        XCTAssertEqual(invalidationCenter.archiveDetailRevision, 0)
    }

    func testDeleteInvalidatesHomeAndArchiveData() async throws {
        let service = FailingFavoriteCaptureService()
        let invalidationCenter = CardDataInvalidationCenter()
        let model = CaptureDetailFeatureModel(
            card: Self.card(isFavorite: false),
            captureService: service,
            invalidationCenter: invalidationCenter
        )

        try await model.delete()

        XCTAssertEqual(service.deletedCaptureID, 42)
        XCTAssertEqual(invalidationCenter.homeRevision, 1)
        XCTAssertEqual(
            invalidationCenter.archiveHomeRevision,
            ArchiveHomeRevision(types: 1, favorites: 1, other: 1)
        )
        XCTAssertEqual(invalidationCenter.archiveDetailRevision, 1)
    }

    func testExpiredImageURLRefreshesDetailOnceAndPreservesCardIdentity() async {
        let oldURL = URL(string: "https://image.test/expired")!
        let refreshedURL = URL(string: "https://image.test/refreshed")!
        let originalCard = Self.card(
            isFavorite: false,
            originalImageURL: oldURL
        )
        let service = RefreshingCaptureService(
            detail: Self.card(
                isFavorite: false,
                originalImageURL: refreshedURL
            )
        )
        let model = CaptureDetailFeatureModel(
            card: originalCard,
            captureService: service,
            invalidationCenter: CardDataInvalidationCenter()
        )

        await model.refreshImageURLAfterFailure(oldURL)
        await model.refreshImageURLAfterFailure(refreshedURL)

        XCTAssertEqual(service.detailRequestCount, 1)
        XCTAssertEqual(model.card.id, originalCard.id)
        XCTAssertEqual(model.card.originalImageURL, refreshedURL)
    }

    func testFavoriteChangeInvalidatesOnlyRelatedData() {
        let invalidationCenter = CardDataInvalidationCenter()

        invalidationCenter.invalidate(.favoriteChanged)

        XCTAssertEqual(invalidationCenter.homeRevision, 1)
        XCTAssertEqual(invalidationCenter.archiveHomeRevision.types, 0)
        XCTAssertEqual(invalidationCenter.archiveHomeRevision.favorites, 1)
        XCTAssertEqual(invalidationCenter.archiveHomeRevision.other, 0)
        XCTAssertEqual(invalidationCenter.archiveDetailRevision, 1)
    }

    func testCaptureCreationInvalidatesAllCardCollections() {
        let invalidationCenter = CardDataInvalidationCenter()

        invalidationCenter.invalidate(.captureCreated)

        XCTAssertEqual(invalidationCenter.homeRevision, 1)
        XCTAssertEqual(
            invalidationCenter.archiveHomeRevision,
            ArchiveHomeRevision(types: 1, favorites: 1, other: 1)
        )
        XCTAssertEqual(invalidationCenter.archiveDetailRevision, 1)
    }

    func testRemoteImageRefreshesOnlyForExpiredAuthorizationResponse() {
        XCTAssertEqual(
            RecapRemoteImageResponsePolicy.failure(for: 403),
            .expiredURL
        )
        XCTAssertEqual(
            RecapRemoteImageResponsePolicy.failure(for: 500),
            .unavailable
        )
        XCTAssertNil(RecapRemoteImageResponsePolicy.failure(for: 200))
    }

    private static func card(
        isFavorite: Bool,
        originalImageURL: URL? = nil
    ) -> InformationCard {
        InformationCard(
            id: UUID(),
            captureID: 42,
            title: "카드",
            summary: "요약",
            collection: .knowledge,
            dateText: "",
            location: "",
            businessHours: "",
            category: "정보 · 지식",
            confirmationLabel: nil,
            memo: "",
            tags: [],
            originalImageURL: originalImageURL,
            isFavorite: isFavorite
        )
    }
}

private final class CaptureNetworkClientStub: NetworkClient, @unchecked Sendable {
    private let lock = NSLock()
    private var storedEndpoints: [APIEndpoint] = []

    var endpoints: [APIEndpoint] {
        lock.withLock { storedEndpoints }
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        lock.withLock { storedEndpoints.append(endpoint) }

        if responseType == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        let json: String
        switch endpoint.path {
        case "/api/v1/captures/upload-urls":
            json = """
            {"success":true,"data":{"uploads":[
              {"imageKey":"a","uploadUrl":"https://upload.test/a"},
              {"imageKey":"b","uploadUrl":"https://upload.test/b"}
            ]},"error":null}
            """
        case "/api/v1/captures/organize":
            json = """
            {"success":true,"data":{"batchId":7,"totalCount":2,"status":"PROCESSING"},"error":null}
            """
        case "/api/v1/captures/organize/7/status":
            json = """
            {"success":true,"data":{"batchId":7,"status":"COMPLETED","totalCount":2,"successCount":2,"failCount":0},"error":null}
            """
        case "/api/v1/captures/organize/pending-result":
            json = """
            {"success":true,"data":null,"error":null}
            """
        case "/api/v1/captures/11":
            json = """
            {"success":true,"data":{"captureId":11,"typeCode":"KNOWLEDGE","title":"제목","summary":"요약","body":"본문","originalImageUrl":"https://image.test/11","isFavorite":false,"organizedAt":"2026-07-23T01:02:03Z"},"error":null}
            """
        default:
            throw APIError.missingResponseData
        }

        return try JSONDecoder.recapAPI.decode(Response.self, from: Data(json.utf8))
    }
}

private final class CaptureServiceStub: CaptureServing, @unchecked Sendable {
    private let lock = NSLock()
    private let uploadItems: [UploadItemDTO]
    private var statusResults: [OrganizeStatusResponseDTO]
    private var storedOrganizedImageKeys: [String] = []
    private var storedStatusRequestCount = 0
    private var storedAcknowledgedBatchIDs: [Int64] = []

    init(
        uploadItems: [UploadItemDTO],
        statusResults: [OrganizeStatusResponseDTO]
    ) {
        self.uploadItems = uploadItems
        self.statusResults = statusResults
    }

    var organizedImageKeys: [String] {
        lock.withLock { storedOrganizedImageKeys }
    }

    var statusRequestCount: Int {
        lock.withLock { storedStatusRequestCount }
    }

    var acknowledgedBatchIDs: [Int64] {
        lock.withLock { storedAcknowledgedBatchIDs }
    }

    func issueUploadURLs(count: Int) async throws -> [UploadItemDTO] { uploadItems }

    func organize(imageKeys: [String]) async throws -> OrganizeResponseDTO {
        lock.withLock { storedOrganizedImageKeys = imageKeys }
        return OrganizeResponseDTO(
            batchId: 9,
            totalCount: imageKeys.count,
            status: .processing
        )
    }

    func organizeStatus(batchID: Int64) async throws -> OrganizeStatusResponseDTO {
        lock.withLock {
            storedStatusRequestCount += 1
            return statusResults.removeFirst()
        }
    }

    func cancelOrganize(batchID: Int64) async throws {}
    func pendingOrganizeResult() async throws -> PendingOrganizeResultDTO? { nil }
    func acknowledgeOrganizeResult(batchID: Int64) async throws {
        lock.withLock { storedAcknowledgedBatchIDs.append(batchID) }
    }
    func captureDetail(captureID: Int64) async throws -> InformationCard {
        throw APIError.missingResponseData
    }
    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {}
    func deleteCapture(captureID: Int64) async throws {}
}

private final class ImageUploaderStub: PresignedImageUploading, @unchecked Sendable {
    private let lock = NSLock()
    private var storedUploadedURLs: [URL] = []

    var uploadedURLs: [URL] {
        lock.withLock { storedUploadedURLs }
    }

    func upload(_ data: Data, to url: URL) async throws {
        lock.withLock { storedUploadedURLs.append(url) }
    }
}

private final class FailingImageUploader: PresignedImageUploading, @unchecked Sendable {
    func upload(_ data: Data, to url: URL) async throws {
        throw CaptureLifecycleError.uploadFailed
    }
}

private final class FailingFavoriteCaptureService: CaptureServing, @unchecked Sendable {
    private let lock = NSLock()
    private var storedDeletedCaptureID: Int64?

    var deletedCaptureID: Int64? {
        lock.withLock { storedDeletedCaptureID }
    }

    func issueUploadURLs(count: Int) async throws -> [UploadItemDTO] { [] }
    func organize(imageKeys: [String]) async throws -> OrganizeResponseDTO {
        throw APIError.transport
    }
    func organizeStatus(batchID: Int64) async throws -> OrganizeStatusResponseDTO {
        throw APIError.transport
    }
    func cancelOrganize(batchID: Int64) async throws {}
    func pendingOrganizeResult() async throws -> PendingOrganizeResultDTO? { nil }
    func acknowledgeOrganizeResult(batchID: Int64) async throws {}
    func captureDetail(captureID: Int64) async throws -> InformationCard {
        throw APIError.transport
    }
    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {
        throw APIError.transport
    }
    func deleteCapture(captureID: Int64) async throws {
        lock.withLock { storedDeletedCaptureID = captureID }
    }
}

private final class RefreshingCaptureService: CaptureServing, @unchecked Sendable {
    private let lock = NSLock()
    private let detail: InformationCard
    private var storedDetailRequestCount = 0

    init(detail: InformationCard) {
        self.detail = detail
    }

    var detailRequestCount: Int {
        lock.withLock { storedDetailRequestCount }
    }

    func issueUploadURLs(count: Int) async throws -> [UploadItemDTO] { [] }
    func organize(imageKeys: [String]) async throws -> OrganizeResponseDTO {
        throw APIError.transport
    }
    func organizeStatus(batchID: Int64) async throws -> OrganizeStatusResponseDTO {
        throw APIError.transport
    }
    func cancelOrganize(batchID: Int64) async throws {}
    func pendingOrganizeResult() async throws -> PendingOrganizeResultDTO? { nil }
    func acknowledgeOrganizeResult(batchID: Int64) async throws {}
    func captureDetail(captureID: Int64) async throws -> InformationCard {
        lock.withLock { storedDetailRequestCount += 1 }
        return detail
    }
    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {}
    func deleteCapture(captureID: Int64) async throws {}
}

private final class PresignedUploadURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private static var storedRequest: URLRequest?
    private static var storedBody: Data?

    static var lastRequest: URLRequest? {
        lock.withLock { storedRequest }
    }

    static var lastBody: Data? {
        lock.withLock { storedBody }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.withLock {
            Self.storedRequest = request
            Self.storedBody = request.httpBody ?? request.httpBodyStream?.readAllData()
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private extension InputStream {
    func readAllData() -> Data {
        open()
        defer { close() }

        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)

        while hasBytesAvailable {
            let count = read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            result.append(buffer, count: count)
        }

        return result
    }
}
