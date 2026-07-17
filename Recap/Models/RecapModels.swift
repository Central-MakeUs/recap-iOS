import Foundation

enum AppPhase: Hashable {
    case onboarding(OnboardingStep)
    case main
}

enum OnboardingStep: Hashable {
    case serviceIntro
    case login
    case permissionGuide
    case shareSetup
    case shareSetupDetail
    case firstCleanup
}

enum MainTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case archive

    var id: String { rawValue }
}

enum SettingsRoute: String, CaseIterable, Hashable, Identifiable {
    case accountManagement
    case notificationSettings
    case dataManagement
    case usageGuide
    case privacyPolicy
    case support

    var id: String { rawValue }
}

enum InitialRange: String, CaseIterable, Identifiable, Hashable {
    case sevenDays
    case thirtyDays
    case threeMonths

    var id: String { rawValue }
}

enum CollectionKind: String, CaseIterable, Identifiable, Hashable {
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
    case ready
    case processing
    case complete
    case waiting
    case failed

    var id: String { rawValue }
}

struct InformationCard: Identifiable, Hashable {
    let id: UUID
    let title: String
    let summary: String
    let collection: CollectionKind
    let dateText: String
    let location: String
    let businessHours: String
    let category: String
    let confirmationLabel: String?
    let memo: String
    let tags: [String]
    let originalImageAssetName: String?
    let thumbnailAssetName: String?
    var isFavorite: Bool

    init(
        id: UUID,
        title: String,
        summary: String,
        collection: CollectionKind,
        dateText: String,
        location: String,
        businessHours: String,
        category: String,
        confirmationLabel: String?,
        memo: String,
        tags: [String],
        originalImageAssetName: String? = nil,
        thumbnailAssetName: String? = nil,
        isFavorite: Bool
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.collection = collection
        self.dateText = dateText
        self.location = location
        self.businessHours = businessHours
        self.category = category
        self.confirmationLabel = confirmationLabel
        self.memo = memo
        self.tags = tags
        self.originalImageAssetName = originalImageAssetName
        self.thumbnailAssetName = thumbnailAssetName
        self.isFavorite = isFavorite
    }
}

struct CollectionSummary: Identifiable, Hashable {
    let kind: CollectionKind
    let count: Int
    let previewTitle: String

    var id: CollectionKind { kind }
}
