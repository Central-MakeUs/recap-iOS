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
    case picking
    case confirmation
    case processing
    case complete
    case partialFailure
    case failure
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
            "일부 스크린샷을 정리하지 못했어요"
        case .failure:
            "스크린샷을 정리하지 못했어요"
        }
    }

    var message: String {
        switch self {
        case .complete:
            "보관함에서 확인해보세요!"
        case .partialFailure:
            "정리된 스크린샷은\n보관함에 저장했어요!"
        case .failure:
            "다음에 다시 시도해주세요."
        }
    }

    var buttonTitle: String {
        self == .complete ? "완료" : "닫기"
    }
}

enum CardCreationFlowDecision {
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
    private(set) var selectedScreenshots: [SelectedScreenshot]
    private(set) var progress: CardCreationProgress
    private(set) var successCount = 0
    private(set) var failedLoadCount = 0
    private let processor: any CardCreationProcessing
    private let invalidationCenter: CardDataInvalidationCenter?
    private let notificationController: OrganizeNotificationController?
    private let backgroundExecution: any OrganizeBackgroundExecuting

    init(
        step: CardCreationFlowStep = .picking,
        screenshots: [CardCreationScreenshot]? = nil,
        progress: CardCreationProgress = .initial,
        processor: (any CardCreationProcessing)? = nil,
        invalidationCenter: CardDataInvalidationCenter? = nil,
        notificationController: OrganizeNotificationController? = nil,
        backgroundExecution: (any OrganizeBackgroundExecuting)? = nil
    ) {
        let screenshots = screenshots ?? []
        self.step = step
        self.screenshots = screenshots
        self.selectedScreenshots = screenshots.compactMap { screenshot in
            screenshot.imageData.map { SelectedScreenshot(imageData: $0) }
        }
        self.progress = progress
        self.processor = processor ?? PreviewCardCreationPipeline()
        self.invalidationCenter = invalidationCenter
        self.notificationController = notificationController
        self.backgroundExecution = backgroundExecution ?? PreviewOrganizeBackgroundExecution()
    }

    var selectedCount: Int { selectedScreenshots.count }

    func receivePickerSelection(imageData: [Data], failedCount: Int, appending: Bool) {
        guard !imageData.isEmpty else {
            if selectedScreenshots.isEmpty {
                failedLoadCount = max(failedCount, 1)
                step = .failure
            } else {
                failedLoadCount += failedCount
                step = .confirmation
            }
            return
        }

        let newScreenshots = imageData.map { SelectedScreenshot(imageData: $0) }
        if appending {
            selectedScreenshots.append(contentsOf: newScreenshots.prefix(20 - selectedScreenshots.count))
            failedLoadCount += failedCount
        } else {
            selectedScreenshots = Array(newScreenshots.prefix(20))
            failedLoadCount = failedCount
        }

        screenshots = selectedScreenshots.map {
            CardCreationScreenshot(kind: .capture, imageData: $0.imageData)
        }
        progress = .initial
        step = .confirmation
    }

    func removeScreenshot(id: SelectedScreenshot.ID) {
        selectedScreenshots.removeAll { $0.id == id }
        screenshots = selectedScreenshots.map {
            CardCreationScreenshot(kind: .capture, imageData: $0.imageData)
        }
    }

    func beginProcessing() {
        guard !selectedScreenshots.isEmpty else { return }
        successCount = 0
        progress = .initial
        step = .processing
    }

    func cancelProcessing() async {
        await processor.cancelCurrentProcess()
        progress = .initial
        step = .picking
    }

    func processSelectedScreenshots() async {
        let images = selectedScreenshots.map(\.imageData)

        await notificationController?.prepareForOrganize()
        backgroundExecution.begin()
        defer { backgroundExecution.end() }

        do {
            let result = try await processor.process(
                images: images,
                progress: { [weak self] update in
                    self?.progress = update
                }
            )
            successCount = result.successCount
            failedLoadCount += result.failCount
            if result.successCount > 0 {
                invalidationCenter?.invalidate(.captureCreated)
            }
            await notificationController?.notifyOrganizeResult(result)

            switch result.status {
            case .completed:
                step = failedLoadCount == 0 ? .complete : .partialFailure
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
            failedLoadCount = max(failedLoadCount, images.count)
            await notificationController?.notifyOrganizeFailure()
            step = .failure
        }
    }

    func reopenPicker() {
        step = .picking
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
