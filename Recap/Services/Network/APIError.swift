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
    case statusCode(Int, serverCode: String?, message: String?)
    case decoding
    case transport
    case missingResponseData
}

nonisolated struct ServerErrorEnvelope: Decodable, Equatable, Sendable {
    let code: String?
    let errorCode: String?
    let message: String?
    let error: String?

    var normalizedCode: String? {
        code ?? errorCode ?? error
    }
}

extension APIError {
    static func status(_ statusCode: Int, data: Data, decoder: JSONDecoder) -> APIError {
        let nestedEnvelope = try? decoder.decode(APIResponse<EmptyResponse>.self, from: data)
        let flatEnvelope = try? decoder.decode(ServerErrorEnvelope.self, from: data)
        let envelope = nestedEnvelope?.error ?? flatEnvelope
        let serverCode = envelope?.normalizedCode
        let message = envelope?.message

        if serverCode == "OAUTH_VERIFICATION_FAILED" {
            return .oauthVerificationFailed(statusCode: statusCode)
        }

        return .statusCode(statusCode, serverCode: serverCode, message: message)
    }
}
