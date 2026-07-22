//
//  NetworkClient.swift
//  Recap
//

import Foundation

protocol NetworkClient: Sendable {
    nonisolated func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response
}

extension NetworkClient {
    nonisolated func send<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        try await send(endpoint, as: Response.self)
    }
}

extension JSONDecoder {
    static var recapAPI: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
