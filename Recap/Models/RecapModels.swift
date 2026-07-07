import Foundation

enum AppPhase: Hashable {
    case onboarding(OnboardingStep)
    case main
}

enum OnboardingStep: Hashable {
    case introLogin
    case permissionGuide
    case rangeSelection
}

enum MainTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case collection
    case myPage

    var id: String { rawValue }
}

enum AppRoute: Hashable {
    case search
    case collectionDetail(CollectionKind)
    case cardDetail(InformationCard.ID)
    case settingsDetail(SettingsRoute)
}

enum SettingsRoute: String, CaseIterable, Hashable, Identifiable {
    case permissions
    case dataPolicy
    case help

    var id: String { rawValue }
}

enum InitialRange: String, CaseIterable, Identifiable, Hashable {
    case sevenDays
    case thirtyDays
    case threeMonths

    var id: String { rawValue }
}

enum CollectionKind: String, CaseIterable, Identifiable, Hashable {
    case revisit
    case comparison
    case archive
    case reference

    var id: String { rawValue }
}

enum HomeStatus: String, CaseIterable, Identifiable, Hashable {
    case ready
    case processing
    case complete
    case waiting

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
}

struct CollectionSummary: Identifiable, Hashable {
    let kind: CollectionKind
    let count: Int
    let previewTitle: String

    var id: CollectionKind { kind }
}
