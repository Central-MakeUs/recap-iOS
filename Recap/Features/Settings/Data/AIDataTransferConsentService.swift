import Foundation

@MainActor
protocol AIDataTransferConsentServing {
    func fetchConsentStatus() async throws -> AIDataTransferConsentStatus
    func grantConsent() async throws
    func revokeConsent() async throws
}

@MainActor
final class AIDataTransferConsentService: AIDataTransferConsentServing {
    private let networkClient: any NetworkClient

    init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchConsentStatus() async throws -> AIDataTransferConsentStatus {
        let response: APIResponse<AIDataTransferConsentStatusDTO> = try await networkClient.send(
            consentEndpoint(method: .get)
        )
        return AIDataTransferConsentStatus(dto: try response.requiredData())
    }

    func grantConsent() async throws {
        let _: EmptyResponse = try await networkClient.send(
            consentEndpoint(method: .post)
        )
    }

    func revokeConsent() async throws {
        let _: EmptyResponse = try await networkClient.send(
            consentEndpoint(method: .delete)
        )
    }

    private func consentEndpoint(method: APIEndpoint.Method) -> APIEndpoint {
        APIEndpoint(
            method: method,
            path: "/api/v1/users/me/consent",
            headers: ["Accept": "application/json"]
        )
        .authorized()
    }
}

nonisolated struct AIDataTransferConsentStatus: Equatable, Sendable {
    let hasConsented: Bool
    let consentedAt: Date?

    init(hasConsented: Bool, consentedAt: Date?) {
        self.hasConsented = hasConsented
        self.consentedAt = consentedAt
    }

    init(dto: AIDataTransferConsentStatusDTO) {
        hasConsented = dto.consented
        consentedAt = dto.consentedAt
    }
}

nonisolated struct AIDataTransferConsentStatusDTO: Decodable, Equatable, Sendable {
    let consented: Bool
    let consentedAt: Date?
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
