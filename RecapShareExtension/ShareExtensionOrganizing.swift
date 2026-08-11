import Foundation

/// 공유 확장이 정리를 맡기는 대상. 실제 서버 호출과 목 구현이 이 면을 공유한다.
protocol ShareExtensionOrganizing: Sendable {
    func organize(
        images: [Data],
        progress: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> ShareOrganizeResult

    func cancelCurrentProcess() async
    func acknowledge(batchID: Int64) async
}

extension ShareExtensionUploadPipeline: ShareExtensionOrganizing {}

/// 시뮬레이터에서 로그인 없이 화면을 확인하기 위한 구현.
///
/// 앱이 `APP_RUNTIME_PROFILE=mock`에서 `PreviewCaptureService`를 쓰는 것과 같은
/// 역할이다. 확장에도 같은 장치가 없어 시뮬레이터로는 정리 화면에 닿을 수 없었다.
actor ShareExtensionMockPipeline: ShareExtensionOrganizing {
    private let stepDuration: Duration

    init(stepDuration: Duration = .milliseconds(700)) {
        self.stepDuration = stepDuration
    }

    func organize(
        images: [Data],
        progress: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> ShareOrganizeResult {
        // 진행률을 실제 업로드처럼 단계적으로 올려 로딩바와 애니메이션을 확인한다.
        for step in 1...5 {
            try await Task.sleep(for: stepDuration)
            await progress(Double(step) / 5)
        }

        return ShareOrganizeResult(
            batchID: 1,
            status: .completed,
            totalCount: images.count,
            successCount: images.count,
            failureCount: 0
        )
    }

    func cancelCurrentProcess() async {}
    func acknowledge(batchID: Int64) async {}
}
