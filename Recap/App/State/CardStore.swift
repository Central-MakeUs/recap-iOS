import Foundation
import Observation

/// 카드 엔티티의 단일 원천.
///
/// `captureID`당 `Card` 인스턴스 하나를 보증하고, 카드 변경을 서버와 동기화한다.
/// 낙관적 갱신과 롤백이 여기 한 벌만 있다. 예전에는 홈·보관함·검색·상세 모델이
/// 각자 사본을 들고 같은 안무를 반복했다.
///
/// 기존 `AIDataTransferConsentStore`·`RecapSessionStore`와 같은 자리다:
/// `@Observable` 공유 상태 + 주입받은 서비스 추상으로 서버 동기화.
@MainActor
@Observable
final class CardStore {
    /// 즐겨찾기 토글이 진행 중인 카드. 뷰가 버튼을 비활성화하는 데 쓴다.
    private(set) var updatingFavoriteIDs: Set<Int64> = []

    private var cardsByID: [Int64: Card] = [:]
    /// 변경 4종(즐겨찾기·편집·삭제·신고)만 묶은 면. 조회·업로드까지 가진
    /// `CaptureServing` 전체를 받을 이유가 없다.
    private let captureMutator: any CaptureMutating
    /// 목록 멤버십이 바뀌는 사건(편집·삭제·즐겨찾기 개수)을 화면들에 알린다.
    /// 별 상태 자체는 공유 `Card`로 실시간이라 신호가 필요 없다.
    private let invalidationCenter: CardDataInvalidationCenter?

    init(
        captureMutator: any CaptureMutating,
        invalidationCenter: CardDataInvalidationCenter? = nil
    ) {
        self.captureMutator = captureMutator
        self.invalidationCenter = invalidationCenter
    }

    // MARK: 조회

    func card(withCaptureID captureID: Int64) -> Card? {
        cardsByID[captureID]
    }

    // MARK: 등록

    /// 스냅샷을 정식 인스턴스로 바꾼다. 이미 있으면 그 인스턴스를 갱신해 돌려주므로
    /// 재조회가 정체성을 깨뜨리지 않는다.
    @discardableResult
    func upsert(_ snapshot: CardSnapshot) -> Card {
        if let existing = cardsByID[snapshot.captureID] {
            existing.update(from: snapshot)
            return existing
        }

        let card = Card(snapshot: snapshot)
        cardsByID[snapshot.captureID] = card
        return card
    }

    @discardableResult
    func upsert(_ snapshots: [CardSnapshot]) -> [Card] {
        snapshots.map { upsert($0) }
    }

    // MARK: 변경

    /// 즐겨찾기를 토글하고 서버에 반영한다. 실패하면 되돌리고 다시 던진다.
    ///
    /// 이미 진행 중인 카드면 아무것도 하지 않고 `nil`을 돌려준다. 중복 탭이
    /// 서버 요청을 겹쳐 보내지 않게 하는 장치라, 호출부는 `nil`이면 토스트도
    /// 띄우지 않으면 된다.
    @discardableResult
    func toggleFavorite(_ card: Card) async throws -> Bool? {
        guard updatingFavoriteIDs.insert(card.captureID).inserted else { return nil }
        defer { updatingFavoriteIDs.remove(card.captureID) }

        card.isFavorite.toggle()

        do {
            try await captureMutator.updateFavorite(
                captureID: card.captureID,
                isFavorite: card.isFavorite
            )
            invalidationCenter?.invalidate(.favoriteChanged)
            return card.isFavorite
        } catch {
            card.isFavorite.toggle()
            throw error
        }
    }

    /// 편집을 서버에 저장하고 공유 인스턴스에 반영한다.
    func saveEdit(_ draft: CardEditDraft, for card: Card) async throws {
        try await captureMutator.updateCapture(captureID: card.captureID, draft: draft)
        applyEdit(draft, toCaptureID: card.captureID)
        invalidationCenter?.invalidate(.captureUpdated)
    }

    /// 편집 내용을 공유 인스턴스에만 반영한다. 서버 저장까지 하려면
    /// `saveEdit(_:for:)`를 쓴다.
    func applyEdit(_ draft: CardEditDraft, toCaptureID captureID: Int64) {
        guard let card = cardsByID[captureID] else { return }

        card.title = draft.title
        card.summary = draft.summary
        card.collection = draft.collection
        card.category = draft.collection.displayTitle
        card.memo = draft.body
    }

    /// 카드를 서버에서 지우고 스토어에서 내린다.
    func delete(_ card: Card) async throws {
        try await captureMutator.deleteCapture(captureID: card.captureID)
        cardsByID[card.captureID] = nil
        invalidationCenter?.invalidate(.captureDeleted)
    }

    /// 여러 카드를 한 번에 지운다. 보관함의 선택 삭제가 쓴다.
    func delete(captureIDs: [Int64]) async throws {
        try await captureMutator.deleteCaptures(captureIDs: captureIDs)
        captureIDs.forEach { cardsByID[$0] = nil }
        invalidationCenter?.invalidate(.captureDeleted)
    }

    /// 카드를 신고한다. 카드 상태는 바뀌지 않지만, 서버 변경 네 종
    /// (즐겨찾기·편집·삭제·신고)의 입구를 한곳에 둔다.
    func report(
        _ card: Card,
        reason: CaptureReportReason,
        detail: String?
    ) async throws {
        try await captureMutator.reportCapture(
            captureID: card.captureID,
            reason: reason,
            detail: detail
        )
    }

    func remove(captureID: Int64) {
        cardsByID[captureID] = nil
    }

    func removeAll() {
        cardsByID.removeAll()
    }
}

extension CardStore {
    /// 토글하고 띄울 토스트를 돌려준다. 중복 탭이라 무시했으면 `nil`.
    ///
    /// 네 화면이 토글 후 토스트 고르는 코드까지 복제하지 않도록 여기로 모았다.
    func toggleFavoriteReturningToast(_ card: Card) async -> RecapToastContent? {
        let wasFavorite = card.isFavorite
        do {
            guard let isFavorite = try await toggleFavorite(card) else { return nil }
            return RecapToastMessage.favoriteToggled(isFavorite: isFavorite).content
        } catch {
            return RecapToastMessage.favoriteToggleFailed(wasFavorite: wasFavorite).content
        }
    }
}
