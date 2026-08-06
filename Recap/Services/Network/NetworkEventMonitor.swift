//
//  NetworkEventMonitor.swift
//  Recap
//

import Alamofire
import Foundation
import Synchronization

nonisolated struct NetworkLogRecord: Equatable, Sendable, CustomStringConvertible {
    var url: URL?
    var statusCode: Int?
    var duration: TimeInterval
    var requestID: String?
    var errorCategory: String?

    var description: String {
        [
            "url=\(url?.absoluteString ?? "nil")",
            "status=\(statusCode.map(String.init) ?? "nil")",
            "duration=\(duration)",
            "requestID=\(requestID ?? "nil")",
            "error=\(errorCategory ?? "nil")"
        ].joined(separator: " ")
    }
}

final class NetworkEventMonitor: EventMonitor {
    let queue = DispatchQueue(label: "com.recap.network-event-monitor")

    /// `queue` 위에서만 접근하지만 컴파일러가 그 사실을 알 수 없어 잠금으로 표현한다.
    private let startedAt = Mutex<[ObjectIdentifier: Date]>([:])
    private let record: @Sendable (NetworkLogRecord) -> Void

    init(record: @escaping @Sendable (NetworkLogRecord) -> Void = { _ in }) {
        self.record = record
    }

    func requestDidResume(_ request: Request) {
        queue.async {
            self.startedAt.withLock { $0[ObjectIdentifier(request)] = Date() }
        }
    }

    func request(
        _ request: Request,
        didCompleteTask task: URLSessionTask,
        with error: AFError?
    ) {
        queue.async {
            let startedAt = self.startedAt.withLock {
                $0.removeValue(forKey: ObjectIdentifier(request))
            }
            let duration = startedAt.map { Date().timeIntervalSince($0) } ?? 0
            let httpResponse = task.response as? HTTPURLResponse
            let originalRequest = task.originalRequest

            self.record(
                NetworkLogRecord(
                    url: Self.redactedURL(from: originalRequest?.url),
                    statusCode: httpResponse?.statusCode,
                    duration: duration,
                    requestID: originalRequest?.value(forHTTPHeaderField: NetworkRequestID.headerName),
                    errorCategory: error.map(Self.errorCategory)
                )
            )
        }
    }

    private static func redactedURL(from url: URL?) -> URL? {
        guard let url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.query = nil
        components.fragment = nil
        return components.url
    }

    private static func errorCategory(_ error: AFError) -> String {
        if let urlError = error.underlyingError as? URLError {
            switch urlError.code {
            case .timedOut:
                return "timeout"
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
                return "offline"
            default:
                return "transport"
            }
        }

        return "transport"
    }
}
