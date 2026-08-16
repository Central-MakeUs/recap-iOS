#if DEBUG
import Foundation

// 프리뷰와 시뮬레이터 목 프로필에서 쓰는 서비스 구현.
//
// 각 서비스 파일에 함께 정의돼 있던 것을 모았다. 프로덕션 파일에서 목 이름이
// 사라져야 배포 빌드에서 제외할 때 감쌀 대상이 파일 단위로 정리된다.

@MainActor
final class PreviewUserAccountService: UserAccountServing {
    private let provider: AuthProvider
    private var capturedCount: Int

    init(provider: AuthProvider = .kakao, capturedCount: Int = 128) {
        self.provider = provider
        self.capturedCount = capturedCount
    }

    func fetchAccountInfo() async throws -> UserAccountInfo {
        UserAccountInfo(
            provider: provider,
            createdAt: Date(timeIntervalSince1970: 1_781_190_000)
        )
    }

    func fetchDataSummary() async throws -> UserDataSummary {
        UserDataSummary(capturedCount: capturedCount)
    }

    func withdrawAccount() async throws {}

    func deleteAllData() async throws {
        capturedCount = 0
    }
}

@MainActor
final class PreviewAIDataTransferConsentService: AIDataTransferConsentServing {
    private var status: AIDataTransferConsentStatus

    init(
        hasConsented: Bool = false,
        consentedAt: Date? = nil
    ) {
        status = AIDataTransferConsentStatus(
            hasConsented: hasConsented,
            consentedAt: consentedAt
        )
    }

    func fetchConsentStatus() async throws -> AIDataTransferConsentStatus {
        status
    }

    func grantConsent() async throws {
        status = AIDataTransferConsentStatus(hasConsented: true, consentedAt: .now)
    }

    func revokeConsent() async throws {
        status = AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil)
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
#endif
