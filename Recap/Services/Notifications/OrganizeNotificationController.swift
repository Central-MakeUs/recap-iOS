import Foundation
import Observation
import UserNotifications

nonisolated enum OrganizeNotificationAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized

    var allowsNotifications: Bool {
        self == .authorized
    }
}

nonisolated struct OrganizeNotificationMessage: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
}

protocol OrganizeNotificationDelivering: Sendable {
    func authorizationStatus() async -> OrganizeNotificationAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func deliver(_ message: OrganizeNotificationMessage) async throws
}

@MainActor
final class SystemOrganizeNotificationDelivery: OrganizeNotificationDelivering {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> OrganizeNotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func deliver(_ message: OrganizeNotificationMessage) async throws {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: message.identifier,
            content: content,
            trigger: nil
        )
        try await center.add(request)
    }
}

@MainActor
@Observable
final class OrganizeNotificationController {
    enum SystemPermissionAction: Equatable {
        case none
        case openSettings
    }

    private static let preferenceKey = "settings.organizeNotificationEnabled"

    private(set) var authorizationStatus: OrganizeNotificationAuthorizationStatus = .notDetermined
    private(set) var isPreferenceEnabled: Bool

    private let delivery: any OrganizeNotificationDelivering
    private let userDefaults: UserDefaults
    private let preferenceKey: String
    private var enableAfterSystemPermission = false
    private var isApplicationInBackground = false

    init(
        delivery: (any OrganizeNotificationDelivering)? = nil,
        userDefaults: UserDefaults = .standard,
        preferenceKey: String? = nil
    ) {
        let resolvedPreferenceKey = preferenceKey ?? Self.preferenceKey

        self.delivery = delivery ?? SystemOrganizeNotificationDelivery()
        self.userDefaults = userDefaults
        self.preferenceKey = resolvedPreferenceKey
        self.isPreferenceEnabled = userDefaults.bool(forKey: resolvedPreferenceKey)
    }

    var isEnabled: Bool {
        isPreferenceEnabled && authorizationStatus.allowsNotifications
    }

    func shouldPresentPermissionGuide() async -> Bool {
        await refreshAuthorization()
        return userDefaults.object(forKey: preferenceKey) == nil
            && authorizationStatus == .notDetermined
    }

    func prepareForOrganize() async {
        await refreshAuthorization()

        guard userDefaults.object(forKey: preferenceKey) == nil else {
            return
        }

        switch authorizationStatus {
        case .authorized:
            savePreference(true)
        case .notDetermined, .denied:
            break
        }
    }

    func requestPermissionForOrganize() async {
        await refreshAuthorization()

        guard authorizationStatus == .notDetermined else {
            if authorizationStatus.allowsNotifications {
                savePreference(true)
            }
            return
        }

        _ = try? await delivery.requestAuthorization()
        await refreshAuthorization()
        if authorizationStatus.allowsNotifications {
            savePreference(true)
        }
    }

    func refreshAuthorization() async {
        authorizationStatus = await delivery.authorizationStatus()

        if authorizationStatus.allowsNotifications, enableAfterSystemPermission {
            enableAfterSystemPermission = false
            savePreference(true)
        }
    }

    func toggleOrganizeNotifications() async -> SystemPermissionAction {
        await refreshAuthorization()

        if isEnabled {
            savePreference(false)
            return .none
        }

        switch authorizationStatus {
        case .authorized:
            savePreference(true)
            return .none
        case .notDetermined:
            _ = try? await delivery.requestAuthorization()
            await refreshAuthorization()
            if authorizationStatus.allowsNotifications {
                savePreference(true)
            }
            return .none
        case .denied:
            enableAfterSystemPermission = true
            return .openSettings
        }
    }

    func enableSystemNotifications() async -> SystemPermissionAction {
        await refreshAuthorization()

        switch authorizationStatus {
        case .authorized:
            return .none
        case .notDetermined:
            _ = try? await delivery.requestAuthorization()
            await refreshAuthorization()
            return .none
        case .denied:
            return .openSettings
        }
    }

    func setApplicationInBackground(_ isInBackground: Bool) {
        isApplicationInBackground = isInBackground
    }

    func notifyOrganizeResult(_ result: OrganizeStatusResponseDTO) async {
        guard isApplicationInBackground, isPreferenceEnabled else { return }

        await refreshAuthorization()
        guard authorizationStatus.allowsNotifications else { return }
        guard let message = OrganizeNotificationMessage(result: result) else { return }

        try? await delivery.deliver(message)
    }

    func notifyOrganizeFailure(batchID: Int64? = nil) async {
        guard isApplicationInBackground, isPreferenceEnabled else { return }

        await refreshAuthorization()
        guard authorizationStatus.allowsNotifications else { return }

        let identifierSuffix = batchID.map(String.init) ?? UUID().uuidString
        try? await delivery.deliver(
            OrganizeNotificationMessage(
                identifier: "recap.organize.result.\(identifierSuffix)",
                title: "스크린샷을 정리하지 못했어요",
                body: "다음에 다시 시도해주세요."
            )
        )
    }

    private func savePreference(_ isEnabled: Bool) {
        isPreferenceEnabled = isEnabled
        userDefaults.set(isEnabled, forKey: preferenceKey)
    }
}

private extension OrganizeNotificationMessage {
    init?(result: OrganizeStatusResponseDTO) {
        let identifier = "recap.organize.result.\(result.batchId)"

        switch result.status {
        case .completed:
            self.init(
                identifier: identifier,
                title: "스크린샷 정리가 완료됐어요",
                body: "\(result.successCount)개의 스크린샷을 정리했어요."
            )
        case .partialFailed:
            self.init(
                identifier: identifier,
                title: "스크린샷 정리가 끝났어요",
                body: "\(result.successCount)개를 정리하고 \(result.failCount)개를 정리하지 못했어요."
            )
        case .failed:
            self.init(
                identifier: identifier,
                title: "스크린샷을 정리하지 못했어요",
                body: "다음에 다시 시도해주세요."
            )
        case .processing, .cancelled:
            return nil
        }
    }
}

actor PreviewOrganizeNotificationDelivery: OrganizeNotificationDelivering {
    func authorizationStatus() async -> OrganizeNotificationAuthorizationStatus {
        .authorized
    }

    func requestAuthorization() async throws -> Bool {
        true
    }

    func deliver(_ message: OrganizeNotificationMessage) async throws {}
}
