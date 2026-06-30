import Foundation
import Combine
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class RECAPDemoModel: ObservableObject {
    @Published var settings = ExperimentSettings()
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var selectedScreenshots: [SelectedScreenshot] = []
    @Published var currentExperiment: OCRExperiment?
    @Published var experiments: [OCRExperiment] = []
    @Published var isRunning = false
    @Published var elapsed: TimeInterval = 0
    @Published var currentImageDuration: TimeInterval = 0
    @Published var appStateDescription = "active"
    @Published var backgroundTaskState = "idle"
    @Published var alertMessage: String?

    private let journal = ExperimentJournal()
    private let processor = OCRExperimentProcessor()
    private var processingTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var runStartedAt: Date?

    var canStart: Bool { !selectedScreenshots.isEmpty && selectedScreenshots.count <= 20 && !isRunning }

    func loadHistory() {
        Task {
            experiments = await journal.loadExperiments()
        }
    }

    func syncSelectedItems() {
        let items = Array(selectedItems.prefix(20))
        if selectedItems.count > 20 {
            selectedItems = items
            alertMessage = "최대 20장까지만 선택할 수 있어요. 초과 선택은 제외했습니다."
        }
        Task {
            var loaded: [SelectedScreenshot] = []
            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { continue }
                    let eligibility = inferEligibility(from: item)
                    loaded.append(SelectedScreenshot(data: data, width: Int(image.size.width * image.scale), height: Int(image.size.height * image.scale), fileSize: Int64(data.count), eligibility: eligibility))
                } catch {
                    alertMessage = "이미지 일부를 읽지 못했습니다: \(error.localizedDescription)"
                }
            }
            selectedScreenshots = loaded
        }
    }

    func startExperiment() {
        guard canStart else { return }
        processingTask?.cancel()
        let screenshots = selectedScreenshots
        var experiment = OCRExperiment(settings: settings, imageCount: screenshots.count)
        experiment.status = .running
        experiment.results = screenshots.enumerated().map { index, screenshot in
            let image = UIImage(data: screenshot.data)
            return OCRImageResult(
                order: index + 1,
                imageData: screenshot.data,
                thumbnailData: image?.jpegDataForThumbnail(),
                width: screenshot.width,
                height: screenshot.height,
                fileSize: screenshot.fileSize,
                eligibility: screenshot.eligibility
            )
        }
        currentExperiment = experiment
        isRunning = true
        elapsed = 0
        currentImageDuration = 0
        runStartedAt = Date()
        startTimer()

        if settings.executionMode == .background {
            processingTask = Task { [experiment] in
                try? await journal.save(experiment)
                let submitResult = BackgroundOCRCoordinator.shared.submit(title: "RE-CAP OCR 처리", subtitle: "\(screenshots.count)장 분석 중")
                switch submitResult {
                case .success(let identifier):
                    backgroundTaskState = "submitted: \(identifier.components(separatedBy: ".").last ?? identifier)"
                    // 실제 OCR은 BGContinuedProcessingTask handler에서 저장된 running experiment를 이어 처리한다.
                case .failure(let error):
                    backgroundTaskState = "submit failed; foreground fallback: \(error.localizedDescription)"
                    await runExperimentForeground(experiment: experiment)
                }
            }
        } else {
            backgroundTaskState = "foreground only"
            processingTask = Task { [experiment] in
                await runExperimentForeground(experiment: experiment)
            }
        }
    }

    func cancelExperiment() {
        processingTask?.cancel()
        processingTask = nil
        timerTask?.cancel()
        isRunning = false
        guard var experiment = currentExperiment else { return }
        experiment.status = .cancelled
        experiment.userCancelled = true
        experiment.finishedAt = Date()
        experiment.totalDuration = runStartedAt.map { Date().timeIntervalSince($0) }
        experiment.results = experiment.results.map { result in
            var updated = result
            if updated.status == .pending || updated.status == .loading || updated.status == .recognizing {
                updated.status = .cancelled
            }
            return updated
        }
        currentExperiment = experiment
        backgroundTaskState = "cancelled"
        Task { try? await journal.save(experiment); loadHistory() }
    }

    func updateAppState(_ phase: ScenePhase) {
        switch phase {
        case .active:
            appStateDescription = "active"
            Task {
                let loaded = await journal.loadExperiments()
                experiments = loaded
                if let id = currentExperiment?.id, let refreshed = loaded.first(where: { $0.id == id }) {
                    currentExperiment = refreshed
                    isRunning = refreshed.status == .running
                    if !isRunning { timerTask?.cancel() }
                }
            }
        case .inactive: appStateDescription = "inactive"
        case .background:
            appStateDescription = "background"
            if var experiment = currentExperiment, experiment.backgroundEnteredAt == nil, isRunning {
                experiment.backgroundEnteredAt = Date()
                experiment.completedBeforeBackground = experiment.succeededCount
                currentExperiment = experiment
                Task { try? await journal.save(experiment) }
            }
        @unknown default: appStateDescription = "unknown"
        }
    }

    func updateResult(_ result: OCRImageResult) {
        guard var experiment = currentExperiment,
              let index = experiment.results.firstIndex(where: { $0.id == result.id }) else { return }
        experiment.results[index] = result
        currentExperiment = experiment
        Task { try? await journal.save(experiment); loadHistory() }
    }

    func delete(_ experiment: OCRExperiment) {
        Task {
            try? await journal.delete(experiment)
            experiments = await journal.loadExperiments()
            if currentExperiment?.id == experiment.id { currentExperiment = nil }
        }
    }

    func exportJSONURL(for experiment: OCRExperiment) async -> URL? {
        try? await journal.exportJSON(experiment)
    }

    func exportCSVURL(for experiment: OCRExperiment) async -> URL? {
        try? await journal.exportCSV(experiment)
    }

    private func runExperimentForeground(experiment: OCRExperiment) async {
        let final = await processor.process(
            experiment: experiment,
            journal: journal,
            isCancelled: { Task.isCancelled },
            onProgress: { [weak self] updated, result in
                guard let self else { return }
                currentExperiment = updated
                if let result {
                    currentImageDuration = result.totalDuration ?? currentImageDuration
                }
            }
        )
        timerTask?.cancel()
        isRunning = false
        currentExperiment = final
        backgroundTaskState = final.settings.executionMode == .background ? "foreground fallback completed" : "completed"
        experiments = await journal.loadExperiments()
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                if let runStartedAt { elapsed = Date().timeIntervalSince(runStartedAt) }
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    private func inferEligibility(from item: PhotosPickerItem) -> ScreenshotEligibility {
        if item.supportedContentTypes.contains(where: { $0.conforms(to: .image) }) {
            return .confirmedScreenshot
        }
        return .unknown
    }
}
