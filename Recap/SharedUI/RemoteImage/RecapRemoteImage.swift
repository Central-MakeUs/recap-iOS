import Observation
import SwiftUI
import UIKit

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

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try Task.checkCancellation()

            guard let response = response as? HTTPURLResponse else {
                state = .failed
                return .unavailable
            }
            if let failure = RecapRemoteImageResponsePolicy.failure(
                for: response.statusCode
            ) {
                state = .failed
                return failure
            }
            guard let image = UIImage(data: data) else {
                state = .failed
                return .unavailable
            }

            state = .loaded(image)
            return nil
        } catch is CancellationError {
            state = .idle
            return nil
        } catch {
            state = .failed
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
    @ViewBuilder let imageContent: (Image) -> ImageContent
    @ViewBuilder let loadingContent: () -> LoadingContent
    @ViewBuilder let failureContent: () -> FailureContent

    @State private var loader = RecapRemoteImageLoader()

    var body: some View {
        Group {
            switch loader.state {
            case .idle, .loading:
                loadingContent()
            case .loaded(let image):
                imageContent(Image(uiImage: image))
            case .failed:
                failureContent()
            }
        }
        .task(id: url) {
            let failure = await loader.load(url)
            guard failure == .expiredURL, !Task.isCancelled else { return }
            onExpiredURL(url)
        }
    }
}
