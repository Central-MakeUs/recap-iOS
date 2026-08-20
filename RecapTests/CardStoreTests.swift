import Synchronization
import XCTest
@testable import Recap

@MainActor
final class CardStoreTests: XCTestCase {
    // MARK: upsert

    func testUpsertKeepsOneInstancePerCaptureID() {
        let store = makeStore().store
        let snapshot = SampleData.cards[0]

        let first = store.upsert(snapshot)
        let second = store.upsert(snapshot)

        XCTAssertNotNil(first)
        XCTAssertTrue(first === second, "같은 captureID는 같은 인스턴스여야 한다")
    }

    func testUpsertRefreshesExistingInstanceFields() {
        let store = makeStore().store
        let snapshot = SampleData.cards[0]
        let card = store.upsert(snapshot)

        let edited = snapshot.with(
            editDraft: CardEditDraft(
                category: snapshot.category,
                title: "재조회로 바뀐 제목",
                summary: snapshot.summary,
                body: snapshot.memo
            )
        )
        store.upsert(edited)

        XCTAssertEqual(card.title, "재조회로 바뀐 제목")
    }

    func testUpsertDistinguishesDifferentCaptureIDs() {
        let store = makeStore().store

        let first = store.upsert(SampleData.cards[0])
        let second = store.upsert(SampleData.cards[1])

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertFalse(first === second)
    }

    func testRefreshImageURLReplacesExpiredListURLWithDetailURL() async {
        let oldURL = URL(string: "https://images.example.com/expired.jpg")!
        let freshURL = URL(string: "https://images.example.com/fresh.jpg")!
        let initial = snapshot(from: SampleData.cards[0], imageURL: oldURL)
        let refreshed = snapshot(from: initial, imageURL: freshURL)
        let loader = CaptureDetailLoaderStub(result: refreshed)
        let store = CardStore(
            captureMutator: CaptureMutatingSpy(favoriteError: nil, favoriteDelay: nil),
            captureDetailLoader: loader
        )
        let card = store.upsert(initial)

        await store.refreshImageURL(for: card, failedURL: oldURL)

        XCTAssertEqual(card.thumbnailURL, freshURL)
        XCTAssertEqual(card.originalImageURL, freshURL)
        XCTAssertEqual(loader.captureIDs, [card.captureID])
    }

    func testRefreshImageURLIgnoresFailureFromStaleURL() async {
        let currentURL = URL(string: "https://images.example.com/current.jpg")!
        let staleURL = URL(string: "https://images.example.com/stale.jpg")!
        let snapshot = snapshot(from: SampleData.cards[0], imageURL: currentURL)
        let loader = CaptureDetailLoaderStub(result: snapshot)
        let store = CardStore(
            captureMutator: CaptureMutatingSpy(favoriteError: nil, favoriteDelay: nil),
            captureDetailLoader: loader
        )
        let card = store.upsert(snapshot)

        await store.refreshImageURL(for: card, failedURL: staleURL)

        XCTAssertTrue(loader.captureIDs.isEmpty)
    }

    // MARK: 즐겨찾기

    func testToggleFavoriteSendsTargetValueAndMutatesCard() async throws {
        let fixture = makeStore()
        let card = fixture.store.upsert(SampleData.cards[0])
        let initialValue = card.isFavorite

        let result = try await fixture.store.toggleFavorite(card)

        XCTAssertEqual(result, !initialValue)
        XCTAssertEqual(card.isFavorite, !initialValue)
        XCTAssertEqual(
            fixture.mutator.favoriteUpdates,
            [FavoriteUpdate(captureID: card.captureID, isFavorite: !initialValue)]
        )
    }

    func testToggleFavoriteRollsBackOnFailure() async throws {
        let fixture = makeStore(favoriteError: TestError.network)
        let card = fixture.store.upsert(SampleData.cards[0])
        let initialValue = card.isFavorite

        do {
            try await fixture.store.toggleFavorite(card)
            XCTFail("실패가 전파돼야 한다")
        } catch {
            XCTAssertEqual(card.isFavorite, initialValue, "실패하면 되돌려야 한다")
        }
    }

    func testToggleFavoriteIgnoresReentrantTap() async throws {
        let fixture = makeStore(favoriteDelay: .milliseconds(100))
        let card = fixture.store.upsert(SampleData.cards[0])

        async let first = fixture.store.toggleFavorite(card)
        // 첫 요청이 updatingFavoriteIDs에 들어갈 시간을 준다.
        try await Task.sleep(for: .milliseconds(20))
        let second = try await fixture.store.toggleFavorite(card)
        let firstResult = try await first

        XCTAssertNotNil(firstResult)
        XCTAssertNil(second, "진행 중 중복 탭은 무시돼야 한다")
        XCTAssertEqual(fixture.mutator.favoriteUpdates.count, 1, "서버 요청은 한 번이어야 한다")
    }

    // MARK: 편집 반영

    func testApplyEditUpdatesSharedInstance() throws {
        let store = makeStore().store
        let card = store.upsert(SampleData.cards[0])
        let draft = CardEditDraft(
            category: .place,
            title: "새 제목",
            summary: "새 요약",
            body: "새 본문"
        )

        store.applyEdit(draft, toCaptureID: card.captureID)

        XCTAssertEqual(card.title, "새 제목")
        XCTAssertEqual(card.summary, "새 요약")
        XCTAssertEqual(card.memo, "새 본문")
        XCTAssertEqual(card.category, .place)
    }

    // MARK: 신고

    func testReportForwardsCaptureIDAndReason() async throws {
        let fixture = makeStore()
        let card = fixture.store.upsert(SampleData.cards[0])

        try await fixture.store.report(card, reason: .inaccurateContent, detail: "가격이 달라요")

        XCTAssertEqual(
            fixture.mutator.reports,
            [CaptureReport(
                captureID: card.captureID,
                reason: .inaccurateContent,
                detail: "가격이 달라요"
            )]
        )
    }

    // MARK: 삭제

    func testRemoveDropsCard() throws {
        let store = makeStore().store
        let card = store.upsert(SampleData.cards[0])

        store.remove(captureID: card.captureID)

        XCTAssertNil(store.card(withCaptureID: card.captureID))
    }

    func testRemoveAllDropsEverything() throws {
        let store = makeStore().store
        let first = store.upsert(SampleData.cards[0])
        let second = store.upsert(SampleData.cards[1])

        store.removeAll()

        XCTAssertNil(store.card(withCaptureID: first.captureID))
        XCTAssertNil(store.card(withCaptureID: second.captureID))
    }

    // MARK: 픽스처

    private func makeStore(
        favoriteError: Error? = nil,
        favoriteDelay: Duration? = nil
    ) -> (store: CardStore, mutator: CaptureMutatingSpy) {
        let mutator = CaptureMutatingSpy(
            favoriteError: favoriteError,
            favoriteDelay: favoriteDelay
        )
        return (CardStore(captureMutator: mutator), mutator)
    }

    private func snapshot(from source: CardSnapshot, imageURL: URL) -> CardSnapshot {
        CardSnapshot(
            captureID: source.captureID,
            title: source.title,
            summary: source.summary,
            category: source.category,
            organizedAt: source.organizedAt,
            location: source.location,
            businessHours: source.businessHours,
            confirmationLabel: source.confirmationLabel,
            memo: source.memo,
            tags: source.tags,
            originalImageAssetName: source.originalImageAssetName,
            thumbnailAssetName: source.thumbnailAssetName,
            originalImageURL: imageURL,
            thumbnailURL: imageURL,
            isFavorite: source.isFavorite
        )
    }
}

private enum TestError: Error {
    case network
}

private struct FavoriteUpdate: Equatable {
    let captureID: Int64
    let isFavorite: Bool
}

private struct CaptureReport: Equatable {
    let captureID: Int64
    let reason: CaptureReportReason
    let detail: String?
}

private final class CaptureMutatingSpy: CaptureMutating {
    private let storedUpdates = Mutex<[FavoriteUpdate]>([])
    private let storedReports = Mutex<[CaptureReport]>([])
    private let favoriteError: Error?
    private let favoriteDelay: Duration?

    init(favoriteError: Error?, favoriteDelay: Duration?) {
        self.favoriteError = favoriteError
        self.favoriteDelay = favoriteDelay
    }

    var favoriteUpdates: [FavoriteUpdate] {
        storedUpdates.withLock { $0 }
    }

    var reports: [CaptureReport] {
        storedReports.withLock { $0 }
    }

    func updateFavorite(captureID: Int64, isFavorite: Bool) async throws {
        if let favoriteDelay {
            try await Task.sleep(for: favoriteDelay)
        }
        if let favoriteError {
            throw favoriteError
        }
        storedUpdates.withLock {
            $0.append(FavoriteUpdate(captureID: captureID, isFavorite: isFavorite))
        }
    }

    func updateCapture(captureID: Int64, draft: CardEditDraft) async throws {}
    func deleteCapture(captureID: Int64) async throws {}
    func deleteCaptures(captureIDs: [Int64]) async throws {}
    func reportCapture(
        captureID: Int64,
        reason: CaptureReportReason,
        detail: String?
    ) async throws {
        storedReports.withLock {
            $0.append(CaptureReport(captureID: captureID, reason: reason, detail: detail))
        }
    }
}

private final class CaptureDetailLoaderStub: CaptureDetailLoading {
    private let storedCaptureIDs = Mutex<[Int64]>([])
    private let result: CardSnapshot

    init(result: CardSnapshot) {
        self.result = result
    }

    var captureIDs: [Int64] {
        storedCaptureIDs.withLock { $0 }
    }

    func captureDetail(captureID: Int64) async throws -> CardSnapshot {
        storedCaptureIDs.withLock { $0.append(captureID) }
        return result
    }
}
