import Foundation

enum MainTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case archive

    var id: String { rawValue }
}

enum SettingsRoute: Hashable {
    case accountManagement
    case notificationSettings
    case dataManagement
    case usageGuide
    case privacyPolicy
    case openSourceLicenses
}

enum InitialRange: String, CaseIterable, Identifiable, Hashable {
    case sevenDays
    case thirtyDays
    case threeMonths

    var id: String { rawValue }
}

nonisolated enum CollectionKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case shopping
    case place
    case schedule
    case knowledge
    case content
    case benefits
    case capture
    case career
    case other

    var id: String { rawValue }

    static let folderCases: [CollectionKind] = [
        .shopping,
        .place,
        .schedule,
        .knowledge,
        .content,
        .benefits,
        .capture,
        .career
    ]
}

enum HomeStatus: String, CaseIterable, Identifiable, Hashable {
    case loading
    case ready
    case processing
    case complete
    case waiting
    case failed

    var id: String { rawValue }
}

nonisolated struct CardSnapshot: Identifiable, Equatable, Sendable {
    /// 서버가 부여한 정체성. `Card`와 같은 키를 쓴다.
    let captureID: Int64
    let title: String
    let summary: String
    let collection: CollectionKind
    let organizedAt: Date?
    let location: String
    let businessHours: String
    let confirmationLabel: String?
    let memo: String
    let tags: [String]
    let originalImageAssetName: String?
    let thumbnailAssetName: String?
    let originalImageURL: URL?
    let thumbnailURL: URL?
    var isFavorite: Bool

    var id: Int64 { captureID }

    init(
        captureID: Int64,
        title: String,
        summary: String,
        collection: CollectionKind,
        organizedAt: Date? = nil,
        location: String,
        businessHours: String,
        confirmationLabel: String?,
        memo: String,
        tags: [String],
        originalImageAssetName: String? = nil,
        thumbnailAssetName: String? = nil,
        originalImageURL: URL? = nil,
        thumbnailURL: URL? = nil,
        isFavorite: Bool
    ) {
        self.captureID = captureID
        self.title = title
        self.summary = summary
        self.collection = collection
        self.organizedAt = organizedAt
        self.location = location
        self.businessHours = businessHours
        self.confirmationLabel = confirmationLabel
        self.memo = memo
        self.tags = tags
        self.originalImageAssetName = originalImageAssetName
        self.thumbnailAssetName = thumbnailAssetName
        self.originalImageURL = originalImageURL
        self.thumbnailURL = thumbnailURL
        self.isFavorite = isFavorite
    }
}

nonisolated struct CollectionSummary: Identifiable, Hashable, Sendable {
    let kind: CollectionKind
    let count: Int
    let previewTitle: String
    let representativeThumbnailURL: URL?

    init(
        kind: CollectionKind,
        count: Int,
        previewTitle: String,
        representativeThumbnailURL: URL? = nil
    ) {
        self.kind = kind
        self.count = count
        self.previewTitle = previewTitle
        self.representativeThumbnailURL = representativeThumbnailURL
    }

    var id: CollectionKind { kind }
}
