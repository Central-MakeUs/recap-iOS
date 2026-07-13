import Foundation
import Observation

nonisolated enum OnboardingProgress: String, Codable, Equatable, Sendable {
    case notStarted
    case loginReady
    case permissionGuide
    case shareSetup
    case shareSetupDetail
    case firstCardCreation
    case completed
}

nonisolated enum OnboardingProgressPersistenceError: Error, Equatable {
    case invalidStoredValue
}

protocol OnboardingProgressPersisting: AnyObject {
    func load() throws -> OnboardingProgress?
    func save(_ progress: OnboardingProgress) throws
}

final class UserDefaultsOnboardingProgressPersistence: OnboardingProgressPersisting {
    private enum Key {
        static let progress = "onboarding.progress"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() throws -> OnboardingProgress? {
        guard let rawValue = userDefaults.string(forKey: Key.progress) else {
            return nil
        }
        guard let progress = OnboardingProgress(rawValue: rawValue) else {
            throw OnboardingProgressPersistenceError.invalidStoredValue
        }
        return progress
    }

    func save(_ progress: OnboardingProgress) throws {
        userDefaults.set(progress.rawValue, forKey: Key.progress)
    }
}

@MainActor
@Observable
final class OnboardingProgressStore {
    private(set) var progress: OnboardingProgress
    private(set) var didFailToPersist = false

    private let persistence: any OnboardingProgressPersisting

    init(
        persistence: any OnboardingProgressPersisting,
        fallbackProgress: OnboardingProgress = .notStarted
    ) {
        self.persistence = persistence

        do {
            self.progress = try persistence.load() ?? fallbackProgress
        } catch {
            self.progress = fallbackProgress
            self.didFailToPersist = true
        }
    }

    func move(to progress: OnboardingProgress) {
        self.progress = progress

        do {
            try persistence.save(progress)
            didFailToPersist = false
        } catch {
            didFailToPersist = true
        }
    }
}
