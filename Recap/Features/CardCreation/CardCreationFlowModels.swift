import Foundation
import Observation
import SwiftUI

struct CardCreationScreenshot: Identifiable, Hashable {
    let id: UUID
    let kind: CollectionKind
    let assetName: String?
    let imageData: Data?

    init(
        id: UUID = UUID(),
        kind: CollectionKind,
        assetName: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.kind = kind
        self.assetName = assetName
        self.imageData = imageData
    }
}

enum CardCreationFlowStep: Hashable {
    case selecting
    case confirming
    case processing
    case complete
    case partialFailure
    case failure
    case noSelection
    case noImages
    case permissionMissing
    case loadFailure
}

enum CardCreationResultState: Hashable {
    case complete
    case partialFailure
    case failure

    func title(selectedCount: Int, failedCount: Int) -> String {
        switch self {
        case .complete:
            "\(selectedCount)개의 스크린샷을\n정리했어요"
        case .partialFailure:
            "\(failedCount)개의 스크린샷 정리를 실패했어요"
        case .failure:
            "스크린샷을 정리하지 못했어요"
        }
    }

    var message: String {
        switch self {
        case .complete:
            "보관함에서 확인해보세요!"
        case .partialFailure, .failure:
            "다음에 다시 시도해보세요"
        }
    }

    var buttonTitle: String { "홈으로" }
}

enum CardCreationFlowDecision {
    static func confirmationStep(selectedCount: Int) -> CardCreationFlowStep {
        selectedCount > 0 ? .confirming : .noSelection
    }

    static func processingResult(failedCount: Int, hasScreenshots: Bool) -> CardCreationFlowStep {
        if failedCount == 0 {
            return .complete
        }
        return hasScreenshots ? .partialFailure : .failure
    }
}

@MainActor
@Observable
final class CardCreationFlowViewModel {
    private(set) var step: CardCreationFlowStep
    private(set) var screenshots: [CardCreationScreenshot]
    var selectedIDs: Set<CardCreationScreenshot.ID>
    private(set) var failedLoadCount = 0
    private let processor: any CardCreationProcessing
    private let invalidationCenter: CardDataInvalidationCenter?

    init(
        step: CardCreationFlowStep = .selecting,
        screenshots: [CardCreationScreenshot]? = nil,
        selectedIDs: Set<CardCreationScreenshot.ID>? = nil,
        processor: (any CardCreationProcessing)? = nil,
        invalidationCenter: CardDataInvalidationCenter? = nil
    ) {
        let screenshots = screenshots ?? []
        self.step = step
        self.screenshots = screenshots
        self.processor = processor ?? PreviewCardCreationPipeline()
        self.invalidationCenter = invalidationCenter
        if let selectedIDs {
            self.selectedIDs = selectedIDs
        } else {
            self.selectedIDs = Set(screenshots.prefix(5).map(\.id))
        }
    }

    var selectedScreenshots: [CardCreationScreenshot] {
        screenshots.filter { selectedIDs.contains($0.id) }
    }

    var selectedCount: Int { selectedIDs.count }
    var hasImages: Bool { !screenshots.isEmpty }
    var canConfirm: Bool { selectedCount > 0 }

    func toggle(_ screenshot: CardCreationScreenshot) {
        if selectedIDs.contains(screenshot.id) {
            selectedIDs.remove(screenshot.id)
        } else {
            selectedIDs.insert(screenshot.id)
        }
    }

    func startSelection() {
        if screenshots.isEmpty {
            step = .noImages
        } else {
            step = .selecting
        }
    }

    func showPermissionMissing() {
        step = .permissionMissing
    }

    func showLoadFailure() {
        step = .loadFailure
    }

    func confirmSelection() {
        step = CardCreationFlowDecision.confirmationStep(selectedCount: selectedCount)
    }

    func addMore() {
        step = screenshots.isEmpty ? .noImages : .selecting
    }

    func remove(_ screenshot: CardCreationScreenshot) {
        selectedIDs.remove(screenshot.id)
        if selectedIDs.isEmpty {
            step = .noSelection
        }
    }

    func startProcessing() {
        guard canConfirm else {
            step = .noSelection
            return
        }
        step = .processing
    }

    func cancelProcessing() async {
        await processor.cancelCurrentProcess()
        step = .confirming
    }

    func processSelectedScreenshots() async {
        let selected = selectedScreenshots
        let images = selected.map { $0.imageData ?? Data() }

        do {
            let result = try await processor.process(images: images)
            failedLoadCount = result.failCount
            if result.successCount > 0 {
                invalidationCenter?.invalidate(.captureCreated)
            }

            switch result.status {
            case .completed:
                step = .complete
            case .partialFailed:
                step = .partialFailure
            case .failed, .cancelled:
                step = .failure
            case .processing:
                step = .failure
            }
        } catch is CancellationError {
            return
        } catch {
            failedLoadCount = max(failedLoadCount, selected.count)
            step = .failure
        }
    }

    func showPartialFailure() {
        step = .partialFailure
    }

    func showFailure() {
        step = .failure
    }

    func retryLoad() {
        step = .selecting
    }

    func replaceScreenshots(with screenshots: [CardCreationScreenshot], failedCount: Int = 0) {
        self.screenshots = screenshots
        failedLoadCount = failedCount
        selectedIDs = Set(screenshots.map(\.id))
        step = screenshots.isEmpty ? .noImages : .selecting
    }

    func failLoadingScreenshots() {
        failedLoadCount = 1
        step = .loadFailure
    }
}

enum CardCreationSampleData {
    static let screenshots: [CardCreationScreenshot] = [
        CardCreationScreenshot(kind: .shopping, assetName: "HomeFavoriteKeyboard"),
        CardCreationScreenshot(kind: .place, assetName: "HomeRecentJeju"),
        CardCreationScreenshot(kind: .schedule, assetName: "HomeFavoriteMove"),
        CardCreationScreenshot(kind: .knowledge, assetName: "HomeRecentReturn"),
        CardCreationScreenshot(kind: .content, assetName: "HomeRecentPasta"),
        CardCreationScreenshot(kind: .benefits, assetName: "HomeFavoriteTax"),
        CardCreationScreenshot(kind: .capture),
        CardCreationScreenshot(kind: .career),
        CardCreationScreenshot(kind: .other)
    ]

}
