import Foundation

actor ExperimentJournal {
    private let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.directory = base.appendingPathComponent("Experiments", isDirectory: true)
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func loadExperiments() async -> [OCRExperiment] {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            let experiments = try files.compactMap { url -> OCRExperiment? in
                let data = try Data(contentsOf: url)
                return try decoder.decode(OCRExperiment.self, from: data)
            }
            return experiments.sorted { $0.startedAt > $1.startedAt }
        } catch {
            return []
        }
    }

    func save(_ experiment: OCRExperiment) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(experiment)
        let url = fileURL(for: experiment.id)
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp, options: [.atomic])
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } else {
            try FileManager.default.moveItem(at: tmp, to: url)
        }
    }

    func delete(_ experiment: OCRExperiment) async throws {
        let url = fileURL(for: experiment.id)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    func exportJSON(_ experiment: OCRExperiment) async throws -> URL {
        try await save(experiment)
        return fileURL(for: experiment.id)
    }

    func exportCSV(_ experiment: OCRExperiment) async throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var rows: [String] = [
            "experiment_id,order,status,eligibility,width,height,file_size,load_duration,ocr_duration,total_duration,confidence,text_blocks,predicted,actual,ocr_quality,is_ambiguous,matched_rules,memo,text_preview"
        ]
        for result in experiment.results.sorted(by: { $0.order < $1.order }) {
            let rules = result.classificationResult?.matchedRules.map { "\($0.category.label):\($0.pattern):\($0.score)" }.joined(separator: "|") ?? ""
            let preview = String(result.recognizedText.prefix(160))
            let fields: [String] = [
                experiment.id.uuidString,
                String(result.order),
                result.status.rawValue,
                result.eligibility.rawValue,
                result.width.map { String($0) } ?? "",
                result.height.map { String($0) } ?? "",
                result.fileSize.map { String($0) } ?? "",
                result.loadDuration.map { String(format: "%.4f", $0) } ?? "",
                result.ocrDuration.map { String(format: "%.4f", $0) } ?? "",
                result.totalDuration.map { String(format: "%.4f", $0) } ?? "",
                result.averageConfidence.map { String(format: "%.3f", $0) } ?? "",
                String(result.textBlockCount),
                result.classificationResult?.predictedCategory.rawValue ?? "",
                result.actualCategory?.rawValue ?? "",
                result.ocrQuality?.rawValue ?? "",
                result.classificationResult.map { String($0.isAmbiguous) } ?? "",
                rules,
                result.evaluationMemo ?? "",
                preview
            ]
            rows.append(fields.map { csvEscape($0) }.joined(separator: ","))
        }
        let url = directory.appendingPathComponent("experiment-\(experiment.id.uuidString).csv")
        try rows.joined(separator: "\n").data(using: .utf8)?.write(to: url, options: [.atomic])
        return url
    }

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent("experiment-\(id.uuidString).json")
    }

    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
