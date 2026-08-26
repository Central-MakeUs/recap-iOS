import Observation
import os
import SwiftUI
import UIKit

/// Kingfisher 도입 전후 원격 이미지 비용을 같은 Instruments trace에서 비교한다.
/// URL에는 민감한 query가 포함될 수 있으므로 식별자나 URL 원문은 기록하지 않는다.
private nonisolated enum RecapRemoteImageMetrics {
    static let log = OSLog(
        subsystem: "com.centralmakeus.recap",
        category: .pointsOfInterest
    )

    static func beginLoad() -> OSSignpostID? {
#if IMAGE_PERFORMANCE_MEASUREMENT
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "RemoteImageLoad", signpostID: signpostID)
        return signpostID
#else
        nil
#endif
    }

    static func endLoad(_ signpostID: OSSignpostID?, outcome: Int) {
#if IMAGE_PERFORMANCE_MEASUREMENT
        guard let signpostID else { return }
        os_signpost(
            .end,
            log: log,
            name: "RemoteImageLoad",
            signpostID: signpostID,
            "outcome=%{public}d",
            outcome
        )
#endif
    }

    static func recordDownload(statusCode: Int, byteCount: Int) {
#if IMAGE_PERFORMANCE_MEASUREMENT
        os_signpost(
            .event,
            log: log,
            name: "RemoteImageDownload",
            "status=%{public}d bytes=%{public}ld",
            statusCode,
            byteCount
        )
#endif
    }

    static func beginDecode() -> OSSignpostID? {
#if IMAGE_PERFORMANCE_MEASUREMENT
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "RemoteImageDecode", signpostID: signpostID)
        return signpostID
#else
        nil
#endif
    }

    static func endDecode(_ signpostID: OSSignpostID?, succeeded: Bool) {
#if IMAGE_PERFORMANCE_MEASUREMENT
        guard let signpostID else { return }
        os_signpost(
            .end,
            log: log,
            name: "RemoteImageDecode",
            signpostID: signpostID,
            "succeeded=%{public}d",
            succeeded ? 1 : 0
        )
#endif
    }
}

nonisolated enum RecapRemoteImageFailure: Equatable, Sendable {
    case expiredURL
    case unavailable
}

nonisolated enum RecapRemoteImageResponsePolicy {
    static func failure(for statusCode: Int) -> RecapRemoteImageFailure? {
        switch statusCode {
        case 200..<300:
            nil
        case 401, 403:
            .expiredURL
        default:
            .unavailable
        }
    }
}

/// UIKit 이미지를 동시성 경계 밖에서 생성한 뒤 MainActor의 화면 상태로 전달한다.
/// UIImage는 불변으로 취급하며 생성 이후 이 래퍼를 통해서만 전달한다.
private nonisolated struct RecapDecodedImage: @unchecked Sendable {
    let image: UIImage
}

private nonisolated enum RecapRemoteImageDecoder {
    static func decode(_ data: Data) async -> RecapDecodedImage? {
        let signpostID = RecapRemoteImageMetrics.beginDecode()
        let image: RecapDecodedImage? = await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: data) else { return nil }
            return RecapDecodedImage(image: image.preparingForDisplay() ?? image)
        }.value
        RecapRemoteImageMetrics.endDecode(signpostID, succeeded: image != nil)
        return image
    }
}

@MainActor
@Observable
private final class RecapRemoteImageLoader {
    enum State {
        case idle
        case loading
        case loaded(UIImage)
        case failed
    }

    private(set) var state: State = .idle

    func load(_ url: URL) async -> RecapRemoteImageFailure? {
        state = .loading
        let signpostID = RecapRemoteImageMetrics.beginLoad()
        var outcome = 0
        defer { RecapRemoteImageMetrics.endLoad(signpostID, outcome: outcome) }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try Task.checkCancellation()

            guard let response = response as? HTTPURLResponse else {
                state = .failed
                outcome = 1
                return .unavailable
            }
            RecapRemoteImageMetrics.recordDownload(
                statusCode: response.statusCode,
                byteCount: data.count
            )
            if let failure = RecapRemoteImageResponsePolicy.failure(
                for: response.statusCode
            ) {
                state = .failed
                outcome = response.statusCode
                return failure
            }
            guard let decodedImage = await RecapRemoteImageDecoder.decode(data) else {
                state = .failed
                outcome = 2
                return .unavailable
            }
            try Task.checkCancellation()

            state = .loaded(decodedImage.image)
            outcome = 200
            return nil
        } catch is CancellationError {
            state = .idle
            outcome = 3
            return nil
        } catch {
            state = .failed
            outcome = 4
            return .unavailable
        }
    }
}

struct RecapRemoteImage<
    ImageContent: View,
    LoadingContent: View,
    FailureContent: View
>: View {
    let url: URL
    let onExpiredURL: (URL) -> Void
    @ViewBuilder let imageContent: (UIImage) -> ImageContent
    @ViewBuilder let loadingContent: () -> LoadingContent
    @ViewBuilder let failureContent: () -> FailureContent
    var onLoadCompletion: (Bool) -> Void = { _ in }

    @State private var loader = RecapRemoteImageLoader()

    var body: some View {
        Group {
            switch loader.state {
            case .idle, .loading:
                loadingContent()
            case .loaded(let image):
                imageContent(image)
            case .failed:
                failureContent()
            }
        }
        .task(id: url) {
            let failure = await loader.load(url)
            switch loader.state {
            case .loaded: onLoadCompletion(true)
            case .failed: onLoadCompletion(false)
            case .idle, .loading: break
            }
            guard failure == .expiredURL, !Task.isCancelled else { return }
            onExpiredURL(url)
        }
    }
}
