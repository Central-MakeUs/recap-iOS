import Foundation
import Observation

/// 상세 화면의 서버 조회 담당. 받은 스냅샷을 `CardStore`에 upsert하는 게 전부다.
///
/// 화면은 스토어의 공유 `Card`를 그리므로, 여기서 정체성을 관리할 일이 없다.
/// 예전에는 자기 스냅샷 사본을 들고 `preservingIdentity`로 UUID를 이어 붙였다.
/// 변경(즐겨찾기·편집·삭제·신고)은 전부 `CardStore`가 맡는다.
@MainActor
@Observable
final class CaptureDetailFeatureModel {
    private(set) var isLoading = false

    private let captureID: Int64
    private let captureService: any CaptureServing
    private let cardStore: CardStore
    private var hasRefreshedImageURL = false

    init(
        captureID: Int64,
        captureService: any CaptureServing,
        cardStore: CardStore
    ) {
        self.captureID = captureID
        self.captureService = captureService
        self.cardStore = cardStore
    }

    func loadDetail() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let detail = try await captureService.captureDetail(captureID: captureID)
            cardStore.upsert(detail)
        } catch {
            // 목록 응답을 유지한다. 기존 상세 UI를 네트워크 오류 화면으로 교체하지 않는다.
        }
    }

    /// 만료된 이미지 URL을 재조회로 한 번만 갱신한다.
    func refreshImageURLAfterFailure(_ failedURL: URL) async {
        guard
            let card = cardStore.card(withCaptureID: captureID),
            failedURL == card.originalImageURL || failedURL == card.thumbnailURL,
            !hasRefreshedImageURL
        else {
            return
        }

        hasRefreshedImageURL = true
        await loadDetail()
    }
}
