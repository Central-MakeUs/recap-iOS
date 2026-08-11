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
