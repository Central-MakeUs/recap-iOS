//
//  APIEndpoint.swift
//  Recap
//

import Foundation

nonisolated struct APIEndpoint: Sendable {
    enum Authorization: Sendable {
        case none
        case bearer
    }

    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    enum Body: Sendable {
        case json(Data)
    }

    var method: Method
    var path: String
    var queryItems: [URLQueryItem]
    var headers: [String: String]
    var body: Body?
    var cachePolicy: URLRequest.CachePolicy
    var authorization: Authorization

    init(
        method: Method,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Body? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        authorization: Authorization = .none
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.authorization = authorization
    }

    func authorized() -> APIEndpoint {
        var endpoint = self
        endpoint.authorization = .bearer
        return endpoint
    }

    func addingHeader(name: String, value: String) -> APIEndpoint {
        var endpoint = self
        endpoint.headers[name] = value
        return endpoint
    }

    static func postJSON<Payload: Encodable>(
        path: String,
        body payload: Payload,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> APIEndpoint {
        let data: Data

        do {
            data = try encoder.encode(payload)
        } catch {
            throw APIError.malformedRequest
        }

        return APIEndpoint(
            method: .post,
            path: path,
            headers: ["Content-Type": "application/json", "Accept": "application/json"],
            body: .json(data),
            cachePolicy: cachePolicy
        )
    }

    func urlRequest(
        baseURL: URL,
        requestID: String = UUID().uuidString
    ) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(normalizedPath),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.malformedRequest
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.malformedRequest
        }

        var request = URLRequest(url: url, cachePolicy: cachePolicy)
        request.httpMethod = method.rawValue
        request.setValue(requestID, forHTTPHeaderField: NetworkRequestID.headerName)

        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        switch body {
        case let .json(data):
            request.httpBody = data
        case .none:
            break
        }

        return request
    }

    private var normalizedPath: String {
        path.split(separator: "/").joined(separator: "/")
    }
}

nonisolated enum NetworkRequestID {
    static let headerName = "X-Request-ID"
}
