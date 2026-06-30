import BackgroundTasks
import Foundation

final class BackgroundOCRCoordinator {
    static let shared = BackgroundOCRCoordinator()
    private let baseIdentifier: String
    private var registered = false
    private let journal = ExperimentJournal()

    private init() {
        let bundle = Bundle.main.bundleIdentifier ?? "oliver.Recap-demo"
        self.baseIdentifier = "\(bundle).continuedProcessing"
    }

    var permittedIdentifier: String { "\(baseIdentifier).*" }

    func register() {
        guard !registered else { return }
        registered = true
        BGTaskScheduler.shared.register(forTaskWithIdentifier: permittedIdentifier, using: nil) { task in
            self.handle(task: task)
        }
    }

    @discardableResult
    func submit(title: String, subtitle: String) -> Result<String, Error> {
        let identifier = "\(baseIdentifier).\(UUID().uuidString)"
        let request = BGContinuedProcessingTaskRequest(identifier: identifier, title: title, subtitle: subtitle)
        request.strategy = .queue
        do {
            try BGTaskScheduler.shared.submit(request)
            return .success(identifier)
        } catch {
            return .failure(error)
        }
    }

    private func handle(task: BGTask) {
        guard let continuedTask = task as? BGContinuedProcessingTask else {
            task.setTaskCompleted(success: false)
            return
        }

        let progress = continuedTask.progress
        progress.totalUnitCount = 1
        progress.completedUnitCount = 0
        continuedTask.updateTitle("RE-CAP OCR 준비 중", subtitle: "저장된 백그라운드 실험을 찾고 있어요")

        var workTask: Task<Void, Never>?
        task.expirationHandler = {
            progress.cancel()
            workTask?.cancel()
        }

        workTask = Task {
            let experiments = await journal.loadExperiments()
            guard var experiment = experiments.first(where: { $0.status == .running && $0.settings.executionMode == .background }) else {
                continuedTask.updateTitle("RE-CAP OCR", subtitle: "처리할 백그라운드 실험이 없어요")
                progress.completedUnitCount = 1
                task.setTaskCompleted(success: false)
                return
            }

            if experiment.backgroundEnteredAt == nil {
                experiment.backgroundEnteredAt = Date()
                experiment.completedBeforeBackground = experiment.succeededCount
                try? await journal.save(experiment)
            }

            progress.totalUnitCount = Int64(max(experiment.imageCount, 1))
            let processor = OCRExperimentProcessor()
            let final = await processor.process(
                experiment: experiment,
                journal: journal,
                isCancelled: { Task.isCancelled || progress.isCancelled },
                onProgress: { updated, result in
                    let done = updated.results.filter { $0.status == .completed || $0.status == .failed || $0.status == .cancelled }.count
                    progress.totalUnitCount = Int64(max(updated.imageCount, 1))
                    progress.completedUnitCount = Int64(done)
                    let current = result.map { "#\($0.order) \($0.status.rawValue)" } ?? "\(done)/\(updated.imageCount) 완료"
                    continuedTask.updateTitle("RE-CAP OCR 처리 중", subtitle: current)
                }
            )

            let success = final.status == .completed
            continuedTask.updateTitle(success ? "RE-CAP OCR 완료" : "RE-CAP OCR 중단", subtitle: "\(final.succeededCount)장 성공 · \(final.failedCount)장 실패")
            task.setTaskCompleted(success: success)
        }
    }
}
