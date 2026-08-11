import UIKit

@MainActor
protocol OrganizeBackgroundExecuting: AnyObject {
    func begin()
    func end()
}

@MainActor
final class SystemOrganizeBackgroundExecution: OrganizeBackgroundExecuting {
    private var taskIdentifier: UIBackgroundTaskIdentifier = .invalid

    func begin() {
        end()

        taskIdentifier = UIApplication.shared.beginBackgroundTask(
            withName: "Recap.Organize"
        ) { [weak self] in
            self?.end()
        }
    }

    func end() {
        guard taskIdentifier != .invalid else { return }

        let identifier = taskIdentifier
        taskIdentifier = .invalid
        UIApplication.shared.endBackgroundTask(identifier)
    }
}

/// 백그라운드 실행 연장을 하지 않는 구현.
///
/// 배경 작업이 필요 없는 호출자를 위한 기본값이다. 목이 아니라 프로덕션 동작이다.
@MainActor
final class NoopOrganizeBackgroundExecution: OrganizeBackgroundExecuting {
    func begin() {}
    func end() {}
}
