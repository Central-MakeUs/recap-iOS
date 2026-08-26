#if IMAGE_PERFORMANCE_MEASUREMENT
import os

/// 성능 측정 빌드에서만 이미지가 화면에 준비되는 시간을 남긴다.
@MainActor
final class ImagePerformanceMeasurement {
    static let shared = ImagePerformanceMeasurement()

    private struct CategoryRun {
        let signpostID: OSSignpostID
        var pendingCaptureIDs: Set<Int64>
    }

    private let log = OSLog(subsystem: "com.centralmakeus.recap", category: .pointsOfInterest)
    private var categoryRun: CategoryRun?
    private var detailRun: (captureID: Int64, signpostID: OSSignpostID)?

    private init() {}

    /// 카테고리 진입 후 처음 표시할 8개 썸네일이 모두 준비될 때까지를 잰다.
    func beginCategory(scope: ArchiveDetailScope, cards: [CardSnapshot]) {
        let targetIDs = Set(cards.prefix(8).compactMap { $0.thumbnailURL == nil ? nil : $0.captureID })
        guard !targetIDs.isEmpty else { return }

        cancelCategoryRunIfNeeded()
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "ArchiveCategoryImagesReady", signpostID: signpostID, "scope=%{public}s expected=%{public}d", scope.measurementName, targetIDs.count)
        categoryRun = CategoryRun(signpostID: signpostID, pendingCaptureIDs: targetIDs)
    }

    func markCategoryThumbnailLoaded(captureID: Int64) {
        guard var categoryRun else { return }
        categoryRun.pendingCaptureIDs.remove(captureID)
        if categoryRun.pendingCaptureIDs.isEmpty {
            os_signpost(.end, log: log, name: "ArchiveCategoryImagesReady", signpostID: categoryRun.signpostID, "outcome=%{public}s", "success")
            self.categoryRun = nil
        } else {
            self.categoryRun = categoryRun
        }
    }

    func beginDetail(captureID: Int64) {
        finishDetailIfNeeded(outcome: "replaced")
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "CardDetailImageReady", signpostID: signpostID)
        detailRun = (captureID, signpostID)
    }

    func finishDetail(captureID: Int64, succeeded: Bool) {
        guard detailRun?.captureID == captureID else { return }
        finishDetailIfNeeded(outcome: succeeded ? "success" : "failure")
    }

    private func cancelCategoryRunIfNeeded() {
        guard let categoryRun else { return }
        os_signpost(.end, log: log, name: "ArchiveCategoryImagesReady", signpostID: categoryRun.signpostID, "outcome=%{public}s", "replaced")
        self.categoryRun = nil
    }

    private func finishDetailIfNeeded(outcome: String) {
        guard let detailRun else { return }
        os_signpost(.end, log: log, name: "CardDetailImageReady", signpostID: detailRun.signpostID, "outcome=%{public}s", outcome)
        self.detailRun = nil
    }
}

private extension ArchiveDetailScope {
    var measurementName: String {
        switch self {
        case .favorites: "favorites"
        case .category: "category"
        }
    }
}
#endif
