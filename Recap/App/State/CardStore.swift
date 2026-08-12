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
    /// 홈 요약 등 아직 스냅샷 사본을 그리는 화면을 위한 다리. 토글 성공 시
    /// 재조회를 유발해 그 화면들도 따라오게 한다(보관함 상세는 예외 —
    /// `CardDataInvalidationCenter` 참고). 모든 화면이 `Card`를 읽게 되면
    /// (#111 5단계) 함께 사라진다.
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
    func upsert(_ snapshot: InformationCard) -> Card? {
        guard let captureID = snapshot.captureID else { return nil }

        if let existing = cardsByID[captureID] {
            existing.update(from: snapshot)
            return existing
        }

        guard let card = Card(snapshot: snapshot) else { return nil }
        cardsByID[captureID] = card
        return card
    }

    @discardableResult
    func upsert(_ snapshots: [InformationCard]) -> [Card] {
        snapshots.compactMap { upsert($0) }
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

    /// 편집 내용을 반영한다. 서버 저장은 기존 편집 흐름이 담당하고, 여기서는
    /// 공유 인스턴스만 맞춘다.
    ///
    /// `captureID`가 옵셔널인 것은 `InformationCard`의 유산이다. 실제로 nil인
    /// 카드는 만들어지지 않으며, 값 타입이 정리되면 함께 사라진다.
    func applyEdit(_ draft: CardEditDraft, toCaptureID captureID: Int64?) {
        guard let captureID, let card = cardsByID[captureID] else { return }

        card.title = draft.title
        card.summary = draft.summary
        card.collection = draft.collection
        card.category = draft.collection.displayTitle
        card.memo = draft.body
    }

    func remove(captureID: Int64?) {
        guard let captureID else { return }
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
