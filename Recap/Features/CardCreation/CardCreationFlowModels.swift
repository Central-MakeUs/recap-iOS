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
    private(set) var progress: CardCreationProgress
    private(set) var successCount = 0
    private(set) var failedLoadCount = 0
    private let processor: any CardCreationProcessing
    private let invalidationCenter: CardDataInvalidationCenter?

    init(
        step: CardCreationFlowStep = .picking,
        screenshots: [CardCreationScreenshot]? = nil,
        progress: CardCreationProgress = .initial,
        processor: (any CardCreationProcessing)? = nil,
        invalidationCenter: CardDataInvalidationCenter? = nil
    ) {
        let screenshots = screenshots ?? []
        self.step = step
        self.screenshots = screenshots
        self.progress = progress
        self.processor = processor ?? PreviewCardCreationPipeline()
        self.invalidationCenter = invalidationCenter
    }

    var selectedCount: Int { screenshots.count }

    func startProcessing(imageData: [Data], failedCount: Int) {
        guard !imageData.isEmpty else {
            failedLoadCount = max(failedCount, 1)
            step = .failure
            return
        }

        screenshots = imageData.map {
            CardCreationScreenshot(kind: .capture, imageData: $0)
        }
        successCount = 0
        failedLoadCount = failedCount
        progress = .initial
        step = .processing
    }

    func cancelProcessing() async {
        await processor.cancelCurrentProcess()
        progress = .initial
        step = .picking
    }

    func processSelectedScreenshots() async {
        let images = screenshots.compactMap(\.imageData)

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
