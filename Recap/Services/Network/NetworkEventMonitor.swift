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
    /// `EventMonitor`가 확장에서 같은 이름의 기본 구현(`.main`)을 제공하므로
    /// 내부에서는 다른 이름으로 참조해 모호성을 피한다.
    private let monitorQueue = DispatchQueue(label: "com.recap.network-event-monitor")

    var queue: DispatchQueue { monitorQueue }

    /// `queue` 위에서만 접근하지만 컴파일러가 그 사실을 알 수 없어 잠금으로 표현한다.
    private let startedAt = Mutex<[ObjectIdentifier: Date]>([:])
    private let record: @Sendable (NetworkLogRecord) -> Void

    init(record: @escaping @Sendable (NetworkLogRecord) -> Void = { _ in }) {
        self.record = record
    }

    func requestDidResume(_ request: Request) {
        monitorQueue.async {
            self.startedAt.withLock { $0[ObjectIdentifier(request)] = Date() }
        }
    }

    func request(
        _ request: Request,
        didCompleteTask task: URLSessionTask,
        with error: AFError?
    ) {
        monitorQueue.async {
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

    /// `didCompleteTask`는 URLSessionTask가 만들어지기 전에 취소되면 오지 않는다.
    /// 그 경우 시작 시각이 남아 쌓이고, 해제된 Request와 같은 주소에 새 Request가
    /// 잡히면 남의 시작 시각을 꺼내 소요 시간이 엉뚱하게 찍힌다.
    /// `requestDidFinish`는 정상 완료·취소 양쪽에서 모두 호출되므로 여기서 정리한다.
    func requestDidFinish(_ request: Request) {
        monitorQueue.async {
            _ = self.startedAt.withLock { $0.removeValue(forKey: ObjectIdentifier(request)) }
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
