import Foundation
import Observation
import SwiftUI

struct OrganizeScreenshot: Identifiable, Hashable {
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

enum OrganizeFlowStep: Hashable {
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

enum OrganizeResultState: Hashable {
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

@MainActor
@Observable
final class OrganizeFlowViewModel {
    private(set) var step: OrganizeFlowStep
    private(set) var screenshots: [OrganizeScreenshot]
    var selectedIDs: Set<OrganizeScreenshot.ID>
    private(set) var failedLoadCount = 0

    init(
        step: OrganizeFlowStep = .selecting,
        screenshots: [OrganizeScreenshot]? = nil,
        selectedIDs: Set<OrganizeScreenshot.ID>? = nil
    ) {
        let screenshots = screenshots ?? []
        self.step = step
        self.screenshots = screenshots
        if let selectedIDs {
            self.selectedIDs = selectedIDs
        } else {
            self.selectedIDs = Set(screenshots.prefix(5).map(\.id))
        }
    }

    var selectedScreenshots: [OrganizeScreenshot] {
        screenshots.filter { selectedIDs.contains($0.id) }
    }

    var selectedCount: Int { selectedIDs.count }
    var hasImages: Bool { !screenshots.isEmpty }
    var canConfirm: Bool { selectedCount > 0 }

    func toggle(_ screenshot: OrganizeScreenshot) {
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
        guard canConfirm else {
            step = .noSelection
            return
        }
        step = .confirming
    }

    func addMore() {
        step = screenshots.isEmpty ? .noImages : .selecting
    }

    func remove(_ screenshot: OrganizeScreenshot) {
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

    func cancelProcessing() {
        step = .confirming
    }

    func finishProcessing() {
        if failedLoadCount == 0 {
            step = .complete
        } else if screenshots.isEmpty {
            step = .failure
        } else {
            step = .partialFailure
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

    func replaceScreenshots(with screenshots: [OrganizeScreenshot], failedCount: Int = 0) {
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

enum OrganizeSampleData {
    static let screenshots: [OrganizeScreenshot] = [
        OrganizeScreenshot(kind: .shopping, assetName: "HomeFavoriteKeyboard"),
        OrganizeScreenshot(kind: .place, assetName: "HomeRecentJeju"),
        OrganizeScreenshot(kind: .schedule, assetName: "HomeFavoriteMove"),
        OrganizeScreenshot(kind: .knowledge, assetName: "HomeRecentReturn"),
        OrganizeScreenshot(kind: .content, assetName: "HomeRecentPasta"),
        OrganizeScreenshot(kind: .benefits, assetName: "HomeFavoriteTax"),
        OrganizeScreenshot(kind: .capture),
        OrganizeScreenshot(kind: .career),
        OrganizeScreenshot(kind: .other)
    ]

}
