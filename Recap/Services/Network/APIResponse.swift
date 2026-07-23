import Foundation

nonisolated struct APIResponse<Payload: Decodable & Sendable>: Decodable, Sendable {
    let success: Bool
    let data: Payload?
    let error: ServerErrorEnvelope?

    init(
        success: Bool,
        data: Payload? = nil,
        error: ServerErrorEnvelope? = nil
    ) {
        self.success = success
        self.data = data
        self.error = error
    }

    func requiredData() throws -> Payload {
        guard let data else {
            throw APIError.missingResponseData
        }
        return data
    }
}

extension APIResponse: Equatable where Payload: Equatable {}

nonisolated struct EmptyResponse: Decodable, Equatable, Sendable {
    init() {}
}
