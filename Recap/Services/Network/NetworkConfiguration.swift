//
//  NetworkConfiguration.swift
//  Recap
//

import Foundation

struct NetworkConfiguration: Sendable {
    var baseURL: URL
    var timeout: TimeInterval
    var urlCache: URLCache?

    init(
        baseURL: URL,
        timeout: TimeInterval = 30,
        urlCache: URLCache? = nil
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.urlCache = urlCache
    }

    static var live: NetworkConfiguration {
        NetworkConfiguration(baseURL: URL(string: "https://re-cap.duckdns.org")!)
    }

    func urlSessionConfiguration(
        protocolClasses: [AnyClass]? = nil
    ) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.urlCache = urlCache

        if let protocolClasses {
            configuration.protocolClasses = protocolClasses
        }

        return configuration
    }
}
