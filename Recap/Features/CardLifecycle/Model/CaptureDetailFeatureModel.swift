import Foundation
import Observation

@MainActor
@Observable
final class CaptureDetailFeatureModel {
    private(set) var card: InformationCard
    private(set) var isLoading = false

    private let captureService: any CaptureServing
    private let invalidationCenter: CardDataInvalidationCenter
    private var refreshedImageURLs: Set<URL> = []

    init(
        card: InformationCard,
        captureService: any CaptureServing,
        invalidationCenter: CardDataInvalidationCenter
    ) {
        self.card = card
        self.captureService = captureService
        self.invalidationCenter = invalidationCenter
    }

    func loadDetail() async {
        guard let captureID = card.captureID, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let detail = try await captureService.captureDetail(captureID: captureID)
            card = InformationCard(
                id: card.id,
                captureID: detail.captureID,
                title: detail.title,
                summary: detail.summary,
                collection: detail.collection,
                organizedAt: detail.organizedAt,
                dateText: detail.dateText,
                location: detail.location,
                businessHours: detail.businessHours,
                category: detail.category,
                confirmationLabel: detail.confirmationLabel,
                memo: detail.memo,
                tags: detail.tags,
                originalImageAssetName: detail.originalImageAssetName,
                thumbnailAssetName: detail.thumbnailAssetName,
                originalImageURL: detail.originalImageURL,
                thumbnailURL: detail.thumbnailURL,
                isFavorite: detail.isFavorite
            )
        } catch {
            // 목록 응답을 유지한다. 기존 상세 UI를 네트워크 오류 화면으로 교체하지 않는다.
        }
    }

    func toggleFavorite() async throws -> Bool {
        guard let captureID = card.captureID else {
            throw CaptureLifecycleError.missingCaptureID
        }

        let previousValue = card.isFavorite
        let targetValue = !previousValue
        card = card.with(isFavorite: targetValue)

        do {
            try await captureService.updateFavorite(
                captureID: captureID,
                isFavorite: targetValue
            )
            invalidationCenter.invalidate()
            return targetValue
        } catch {
            card = card.with(isFavorite: previousValue)
            throw error
        }
    }

    func delete() async throws {
        guard let captureID = card.captureID else {
            throw CaptureLifecycleError.missingCaptureID
        }

        try await captureService.deleteCapture(captureID: captureID)
        invalidationCenter.invalidate()
    }

    func refreshImageURLAfterFailure(_ failedURL: URL) async {
        guard
            failedURL == card.originalImageURL || failedURL == card.thumbnailURL,
            refreshedImageURLs.insert(failedURL).inserted
        else {
            return
        }

        await loadDetail()
    }
}
