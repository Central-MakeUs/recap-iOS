import Foundation

struct OCRExperimentProcessor {
    private let ocrService = VisionOCRService()
    private let classifier = RuleBasedClassifier()

    func process(
        experiment initialExperiment: OCRExperiment,
        journal: ExperimentJournal,
        isCancelled: @escaping () -> Bool,
        onProgress: ((OCRExperiment, OCRImageResult?) async -> Void)? = nil
    ) async -> OCRExperiment {
        var experiment = initialExperiment
        let start = Date()
        if experiment.status != .running {
            experiment.status = .running
        }
        try? await journal.save(experiment)
        await onProgress?(experiment, nil)

        for index in experiment.results.indices {
            if isCancelled() { break }
            if experiment.results[index].status == .completed || experiment.results[index].status == .failed {
                continue
            }

            var result = experiment.results[index]
            let itemStart = Date()
            result.status = .loading
            result.loadDuration = 0
            experiment.results[index] = result
            try? await journal.save(experiment)
            await onProgress?(experiment, result)

            guard result.eligibility != .unsupported else {
                result.status = .failed
                result.errorMessage = "스크린샷으로 확인되지 않은 이미지입니다."
                result.totalDuration = Date().timeIntervalSince(itemStart)
                experiment.results[index] = result
                try? await journal.save(experiment)
                await onProgress?(experiment, result)
                continue
            }

            do {
                result.status = .recognizing
                experiment.results[index] = result
                try? await journal.save(experiment)
                await onProgress?(experiment, result)

                let payload = try await ocrService.recognize(data: result.imageData ?? Data(), settings: experiment.settings)
                result.status = .completed
                result.recognizedText = payload.text
                result.averageConfidence = payload.averageConfidence
                result.textBlockCount = payload.textBlockCount
                result.ocrDuration = payload.ocrDuration
                result.transformDuration = payload.transformDuration
                result.totalDuration = Date().timeIntervalSince(itemStart)
                result.classificationResult = classifier.classify(payload.text)
            } catch {
                result.status = .failed
                result.errorMessage = error.localizedDescription
                result.totalDuration = Date().timeIntervalSince(itemStart)
            }

            experiment.results[index] = result
            if experiment.firstResultDuration == nil, result.status == .completed {
                experiment.firstResultDuration = Date().timeIntervalSince(start)
            }
            if experiment.backgroundEnteredAt != nil, result.status == .completed {
                experiment.completedInBackground += 1
            }
            try? await journal.save(experiment)
            await onProgress?(experiment, result)
        }

        experiment.finishedAt = Date()
        experiment.totalDuration = Date().timeIntervalSince(start)
        if isCancelled() {
            experiment.status = .cancelled
            experiment.systemInterrupted = true
            experiment.results = experiment.results.map { result in
                var updated = result
                if updated.status == .pending || updated.status == .loading || updated.status == .recognizing {
                    updated.status = .cancelled
                }
                return updated
            }
        } else {
            experiment.status = .completed
        }
        try? await journal.save(experiment)
        await onProgress?(experiment, nil)
        return experiment
    }
}
