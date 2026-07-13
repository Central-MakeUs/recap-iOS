//
//  APIError.swift
//  Recap
//

import Foundation

nonisolated enum APIError: Error, Equatable, Sendable {
    case malformedRequest
    case nonHTTPResponse
    case timeout
    case offline
    case oauthVerificationFailed(statusCode: Int)
    case statusCode(Int, serverCode: String?)
    case decoding
    case transport
}

nonisolated struct ServerErrorEnvelope: Decodable, Equatable {
    let code: String?
    let errorCode: String?
    let message: String?
    let error: String?

    var normalizedCode: String? {
        code ?? errorCode ?? error
    }
}

private nonisolated struct BackendErrorEnvelope: Decodable {
    let success: Bool?
    let error: ServerErrorEnvelope?
}

extension APIError {
    static func status(_ statusCode: Int, data: Data, decoder: JSONDecoder) -> APIError {
        let nestedEnvelope = try? decoder.decode(BackendErrorEnvelope.self, from: data)
        let flatEnvelope = try? decoder.decode(ServerErrorEnvelope.self, from: data)
        let envelope = nestedEnvelope?.error ?? flatEnvelope
        let serverCode = envelope?.normalizedCode

        if serverCode == "OAUTH_VERIFICATION_FAILED" {
            return .oauthVerificationFailed(statusCode: statusCode)
        }

        return .statusCode(statusCode, serverCode: serverCode)
    }
}
