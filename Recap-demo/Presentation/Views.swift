import PhotosUI
import SwiftUI
import UIKit

struct ExperimentSetupView: View {
    @ObservedObject var model: RECAPDemoModel

    var body: some View {
        Form {
            Section("실험 조건") {
                Picker("OCR 실행 모드", selection: $model.settings.executionMode) {
                    ForEach(ExecutionMode.allCases) { Text($0.label).tag($0) }
                }
                Picker("OCR 인식 수준", selection: $model.settings.recognitionLevel) {
                    ForEach(OCRRecognitionLevel.allCases) { Text($0.label).tag($0) }
                }
                Picker("인식 언어", selection: $model.settings.languageMode) {
                    ForEach(RecognitionLanguageMode.allCases) { Text($0.label).tag($0) }
                }
                Toggle("언어 교정", isOn: $model.settings.usesLanguageCorrection)
                TextField("실험 메모", text: $model.settings.memo, axis: .vertical)
            }

            Section("스크린샷 선택") {
                PhotosPicker(selection: $model.selectedItems, maxSelectionCount: 20, matching: .screenshots) {
                    Label("스크린샷 선택", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: model.selectedItems) { _, _ in model.syncSelectedItems() }

                Text("선택: \(model.selectedScreenshots.count) / 20")
                    .font(.headline)
                if !model.selectedScreenshots.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 76))]) {
                        ForEach(model.selectedScreenshots) { screenshot in
                            ThumbnailCell(screenshot: screenshot)
                        }
                    }
                }
                Button {
                    model.startExperiment()
                } label: {
                    Label("OCR 시작", systemImage: model.settings.executionMode == .background ? "moon.zzz" : "text.viewfinder")
                }
                .disabled(!model.canStart)
            }

            Section("이전 실험") {
                NavigationLink("실험 기록 보기", value: Route.history)
                Text("최근 기록: \(model.experiments.count)개")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("RE-CAP OCR 데모")
    }
}

struct ThumbnailCell: View {
    let screenshot: SelectedScreenshot

    var body: some View {
        VStack(spacing: 6) {
            if let image = UIImage(data: screenshot.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 76, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Text(screenshot.eligibility.label)
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

struct OCRProcessingView: View {
    @ObservedObject var model: RECAPDemoModel

    var body: some View {
        let experiment = model.currentExperiment
        List {
            Section("OCR 처리 상태") {
                if let experiment {
                    ProgressView(value: Double(experiment.succeededCount + experiment.failedCount), total: Double(max(experiment.imageCount, 1)))
                    MetricRow("진행률", "\(experiment.succeededCount + experiment.failedCount) / \(experiment.imageCount)")
                    MetricRow("성공 / 실패", "\(experiment.succeededCount) / \(experiment.failedCount)")
                    MetricRow("전체 경과", model.elapsed.secondsText)
                    MetricRow("현재 이미지 OCR", model.currentImageDuration.secondsText)
                    MetricRow("앱 상태", model.appStateDescription)
                    MetricRow("백그라운드 작업", model.backgroundTaskState)
                } else {
                    ContentUnavailableView("진행 중인 실험 없음", systemImage: "text.viewfinder")
                }
                Button(role: .destructive) { model.cancelExperiment() } label: { Text("취소") }
                    .disabled(!model.isRunning)
            }

            if let experiment {
                Section("이미지별 결과") {
                    ForEach(experiment.results.sorted(by: { $0.order < $1.order })) { result in
                        NavigationLink(value: Route.detail(result.id)) {
                            ResultRow(result: result)
                        }
                    }
                }
            }
        }
        .navigationTitle("OCR 처리")
    }
}

struct OCRResultListView: View {
    @ObservedObject var model: RECAPDemoModel
    let experiment: OCRExperiment

    var liveExperiment: OCRExperiment { model.currentExperiment?.id == experiment.id ? (model.currentExperiment ?? experiment) : experiment }

    var body: some View {
        List {
            Section("요약") {
                MetricRow("이미지 수", "\(liveExperiment.imageCount)")
                MetricRow("성공 / 실패", "\(liveExperiment.succeededCount) / \(liveExperiment.failedCount)")
                MetricRow("전체 처리 시간", liveExperiment.totalDuration?.secondsText ?? "-")
                MetricRow("장당 평균", liveExperiment.averageImageDuration?.secondsText ?? "-")
                MetricRow("최장 처리", liveExperiment.maxImageDuration?.secondsText ?? "-")
                MetricRow("정답 / 오답 / 미평가", "\(liveExperiment.correctCount) / \(liveExperiment.incorrectCount) / \(liveExperiment.imageCount - liveExperiment.evaluatedCount)")
                MetricRow("룰 정확도", liveExperiment.accuracy.map { String(format: "%.1f%%", $0 * 100) } ?? "-")
            }

            Section("내보내기") {
                ExportButtons(model: model, experiment: liveExperiment)
            }

            Section("결과") {
                ForEach(liveExperiment.results.sorted(by: { $0.order < $1.order })) { result in
                    NavigationLink(value: Route.detail(result.id)) {
                        ResultRow(result: result)
                    }
                }
            }
        }
        .navigationTitle("결과 목록")
    }
}

struct OCRResultDetailView: View {
    @ObservedObject var model: RECAPDemoModel
    @State var result: OCRImageResult

    var body: some View {
        Form {
            Section("원본") {
                if let data = result.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 420)
                }
                MetricRow("이미지", "\(result.width ?? 0) × \(result.height ?? 0) · \(ByteCountFormatter.string(fromByteCount: result.fileSize ?? 0, countStyle: .file))")
                MetricRow("스크린샷 판정", result.eligibility.label)
            }

            Section("OCR") {
                MetricRow("상태", result.status.rawValue)
                MetricRow("Confidence", result.averageConfidence.map { String(format: "%.2f", $0) } ?? "-")
                MetricRow("텍스트 블록", "\(result.textBlockCount)")
                MetricRow("OCR 시간", result.ocrDuration?.secondsText ?? "-")
                Text(result.recognizedText.isEmpty ? "텍스트 없음" : result.recognizedText)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }

            if let classification = result.classificationResult {
                Section("룰베이스 분류") {
                    MetricRow("예측", classification.predictedCategory.label)
                    MetricRow("룰 확신", classification.confidence.label)
                    MetricRow("점수 / 격차", "\(classification.winningScore)점 / +\(classification.scoreGap)")
                    MetricRow("검토 필요", classification.isAmbiguous ? "예" : "아니오")
                    ForEach(ScreenshotCategory.allCases) { category in
                        MetricRow(category.label, "\(classification.scores[category, default: 0])점")
                    }
                    if !classification.matchedRules.isEmpty {
                        ForEach(classification.matchedRules) { rule in
                            Text("\(rule.category.shortLabel) +\(rule.score): \(rule.pattern)")
                        }
                    }
                }
            }

            Section("수동 평가") {
                Picker("OCR 품질", selection: bindingQuality) {
                    Text("미평가").tag(nil as OCRQuality?)
                    ForEach(OCRQuality.allCases) { Text($0.label).tag(Optional($0)) }
                }
                Picker("실제 카테고리", selection: bindingCategory) {
                    Text("미평가").tag(nil as ScreenshotCategory?)
                    ForEach(ScreenshotCategory.allCases) { Text($0.label).tag(Optional($0)) }
                }
                TextField("평가 메모", text: Binding(get: { result.evaluationMemo ?? "" }, set: { result.evaluationMemo = $0 }), axis: .vertical)
                Button("평가 저장") { model.updateResult(result) }
            }
        }
        .navigationTitle("#\(result.order) 상세 평가")
    }

    private var bindingQuality: Binding<OCRQuality?> {
        Binding(get: { result.ocrQuality }, set: { result.ocrQuality = $0 })
    }

    private var bindingCategory: Binding<ScreenshotCategory?> {
        Binding(get: { result.actualCategory }, set: { result.actualCategory = $0 })
    }
}

struct ExperimentHistoryView: View {
    @ObservedObject var model: RECAPDemoModel

    var body: some View {
        List {
            if model.experiments.isEmpty {
                ContentUnavailableView("저장된 실험 없음", systemImage: "archivebox")
            }
            ForEach(model.experiments) { experiment in
                NavigationLink(value: Route.resultList(experiment.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(experiment.startedAt.formatted(date: .abbreviated, time: .standard))
                            .font(.headline)
                        Text("\(experiment.imageCount)장 · \(experiment.settings.summary)")
                            .font(.subheadline)
                        Text("성공률 \(successRateText(experiment)) · 정확도 \(experiment.accuracy.map { String(format: "%.1f%%", $0 * 100) } ?? "-")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                offsets.map { model.experiments[$0] }.forEach(model.delete)
            }
        }
        .navigationTitle("실험 기록")
        .toolbar { Button("새로고침") { model.loadHistory() } }
    }

    private func successRateText(_ experiment: OCRExperiment) -> String {
        guard experiment.imageCount > 0 else { return "-" }
        return String(format: "%.1f%%", Double(experiment.succeededCount) / Double(experiment.imageCount) * 100)
    }
}

struct ExportButtons: View {
    @ObservedObject var model: RECAPDemoModel
    let experiment: OCRExperiment
    @State private var jsonURL: URL?
    @State private var csvURL: URL?

    var body: some View {
        VStack(alignment: .leading) {
            Button("JSON 생성") {
                Task { jsonURL = await model.exportJSONURL(for: experiment) }
            }
            if let jsonURL { ShareLink(item: jsonURL) { Label("JSON 내보내기", systemImage: "square.and.arrow.up") } }
            Button("CSV 생성") {
                Task { csvURL = await model.exportCSVURL(for: experiment) }
            }
            if let csvURL { ShareLink(item: csvURL) { Label("CSV 내보내기", systemImage: "tablecells") } }
        }
    }
}

struct ResultRow: View {
    let result: OCRImageResult

    var body: some View {
        HStack(spacing: 12) {
            if let data = result.thumbnailData ?? result.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.2)).frame(width: 56, height: 68)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("#\(result.order) · \(result.status.rawValue)").font(.headline)
                HStack(spacing: 6) {
                    Text(result.classificationResult?.predictedCategory.label ?? "분류 전")
                    if result.classificationResult?.isAmbiguous == true {
                        Text("낮은 확신")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.yellow.opacity(0.25), in: Capsule())
                    }
                }
                .font(.subheadline)
                Text(result.recognizedText.isEmpty ? result.errorMessage ?? "OCR 대기" : String(result.recognizedText.prefix(72)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            if result.actualCategory != nil { Image(systemName: "checkmark.seal.fill").foregroundStyle(.green) }
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String

    init(_ title: String, _ value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
        }
    }
}
