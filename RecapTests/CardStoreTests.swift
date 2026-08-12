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
                collection: snapshot.collection,
                title: "재조회로 바뀐 제목",
                summary: snapshot.summary,
                body: snapshot.memo
            )
        )
        store.upsert(edited)

        XCTAssertEqual(card?.title, "재조회로 바뀐 제목")
    }

    func testUpsertDistinguishesDifferentCaptureIDs() {
        let store = makeStore().store

        let first = store.upsert(SampleData.cards[0])
        let second = store.upsert(SampleData.cards[1])

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertFalse(first === second)
    }

    // MARK: 즐겨찾기

    func testToggleFavoriteSendsTargetValueAndMutatesCard() async throws {
        let fixture = makeStore()
        let card = try XCTUnwrap(store(fixture).upsert(SampleData.cards[0]))
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
        let card = try XCTUnwrap(fixture.store.upsert(SampleData.cards[0]))
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
        let card = try XCTUnwrap(fixture.store.upsert(SampleData.cards[0]))

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
        let card = try XCTUnwrap(store.upsert(SampleData.cards[0]))
        let draft = CardEditDraft(
            collection: .place,
            title: "새 제목",
            summary: "새 요약",
            body: "새 본문"
        )

        store.applyEdit(draft, toCaptureID: card.captureID)

        XCTAssertEqual(card.title, "새 제목")
        XCTAssertEqual(card.summary, "새 요약")
        XCTAssertEqual(card.memo, "새 본문")
        XCTAssertEqual(card.collection, .place)
        XCTAssertEqual(card.category, CollectionKind.place.displayTitle)
    }

    // MARK: 신고

    func testReportForwardsCaptureIDAndReason() async throws {
        let fixture = makeStore()
        let card = try XCTUnwrap(fixture.store.upsert(SampleData.cards[0]))

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
        let card = try XCTUnwrap(store.upsert(SampleData.cards[0]))

        store.remove(captureID: card.captureID)

        XCTAssertNil(store.card(withCaptureID: card.captureID))
    }

    func testRemoveAllDropsEverything() throws {
        let store = makeStore().store
        let first = try XCTUnwrap(store.upsert(SampleData.cards[0]))
        let second = try XCTUnwrap(store.upsert(SampleData.cards[1]))

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

    private func store(_ fixture: (store: CardStore, mutator: CaptureMutatingSpy)) -> CardStore {
        fixture.store
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
