import Foundation

protocol PresignedImageUploading: Sendable {
    func upload(_ data: Data, to url: URL) async throws
}

final class URLSessionPresignedImageUploader: PresignedImageUploading {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func upload(_ data: Data, to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await session.upload(for: request, from: data)
        guard
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            throw CaptureLifecycleError.uploadFailed
        }
    }
}
