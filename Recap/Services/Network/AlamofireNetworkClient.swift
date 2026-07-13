//
//  AlamofireNetworkClient.swift
//  Recap
//

import Alamofire
import Foundation

final class AlamofireNetworkClient: NetworkClient, @unchecked Sendable {
    private let configuration: NetworkConfiguration
    private let session: Session
    private let decoder: JSONDecoder

    init(
        configuration: NetworkConfiguration = .live,
        decoder: JSONDecoder = .recapAPI,
        eventRecorder: @escaping @Sendable (NetworkLogRecord) -> Void = { _ in }
    ) {
        self.configuration = configuration
        self.decoder = decoder
        self.session = Session(
            configuration: configuration.urlSessionConfiguration(),
            eventMonitors: [NetworkEventMonitor(record: eventRecorder)]
        )
    }

    init(
        configuration: NetworkConfiguration,
        urlSessionConfiguration: URLSessionConfiguration,
        decoder: JSONDecoder = .recapAPI,
        eventRecorder: @escaping @Sendable (NetworkLogRecord) -> Void = { _ in }
    ) {
        self.configuration = configuration
        self.decoder = decoder
        self.session = Session(
            configuration: urlSessionConfiguration,
            eventMonitors: [NetworkEventMonitor(record: eventRecorder)]
        )
    }

    nonisolated func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        let request: URLRequest

        do {
            request = try endpoint.urlRequest(baseURL: configuration.baseURL)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.malformedRequest
        }

        let response = await session
            .request(request)
            .serializingData()
            .response

        if response.response == nil, response.data != nil {
            throw APIError.nonHTTPResponse
        }

        guard let httpResponse = response.response else {
            if let error = response.error {
                let normalizedError = Self.normalizedTransportError(error)

                if normalizedError == .timeout || normalizedError == .offline {
                    throw normalizedError
                }
                if response.data != nil || !Self.isURLSessionTransportError(error) {
                    throw APIError.nonHTTPResponse
                }

                throw normalizedError
            }

            throw APIError.nonHTTPResponse
        }

        if let error = response.error {
            throw Self.normalizedTransportError(error)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.status(httpResponse.statusCode, data: response.data ?? Data(), decoder: decoder)
        }

        do {
            return try decoder.decode(Response.self, from: response.data ?? Data())
        } catch {
            throw APIError.decoding
        }
    }

    private nonisolated static func normalizedTransportError(_ error: AFError) -> APIError {
        if let urlError = error.underlyingError as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
                return .offline
            case .badServerResponse, .cannotParseResponse:
                return .nonHTTPResponse
            default:
                return .transport
            }
        }

        return .transport
    }

    private nonisolated static func isURLSessionTransportError(_ error: AFError) -> Bool {
        guard let underlyingError = error.underlyingError as NSError? else {
            return false
        }

        return underlyingError.domain == NSURLErrorDomain
    }
}
