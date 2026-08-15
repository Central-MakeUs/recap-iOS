import Foundation
import Observation

/// AI 데이터 전송 동의 상태. 원본은 서버이며 로컬에 남기지 않는다.
/// 읽는 쪽(설정 화면, 카드 생성 흐름)이 모두 표시 직전에 `refresh()`를 호출하므로
/// 캐시 없이도 항상 서버 값을 본다.
@MainActor
@Observable
final class AIDataTransferConsentStore {
    private let service: any AIDataTransferConsentServing
    private(set) var hasConsented = false
    private(set) var consentedAt: Date?

    init(service: any AIDataTransferConsentServing) {
        self.service = service
    }

    func refresh() async throws {
        apply(try await service.fetchConsentStatus())
    }

    func grantConsent() async throws {
        try await service.grantConsent()
        apply(try await service.fetchConsentStatus())
    }

    func revokeConsent() async throws {
        try await service.revokeConsent()
        apply(AIDataTransferConsentStatus(hasConsented: false, consentedAt: nil))
    }

    private func apply(_ status: AIDataTransferConsentStatus) {
        hasConsented = status.hasConsented
        consentedAt = status.consentedAt
    }
}
