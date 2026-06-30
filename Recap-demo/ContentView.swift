import SwiftUI

enum Route: Hashable {
    case processing
    case history
    case resultList(UUID)
    case detail(UUID)
}

struct ContentView: View {
    @StateObject private var model = RECAPDemoModel()
    @State private var path: [Route] = []
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $path) {
            ExperimentSetupView(model: model)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .processing:
                        OCRProcessingView(model: model)
                    case .history:
                        ExperimentHistoryView(model: model)
                    case .resultList(let id):
                        if let experiment = (model.currentExperiment?.id == id ? model.currentExperiment : model.experiments.first { $0.id == id }) {
                            OCRResultListView(model: model, experiment: experiment)
                        } else {
                            ContentUnavailableView("실험을 찾을 수 없음", systemImage: "questionmark.folder")
                        }
                    case .detail(let id):
                        if let result = findResult(id) {
                            OCRResultDetailView(model: model, result: result)
                        } else {
                            ContentUnavailableView("결과를 찾을 수 없음", systemImage: "questionmark.folder")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button { path.append(.processing) } label: { Label("처리 화면", systemImage: "text.viewfinder") }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button { path.append(.history) } label: { Label("기록", systemImage: "clock.arrow.circlepath") }
                    }
                }
        }
        .onAppear { model.loadHistory() }
        .onChange(of: scenePhase) { _, newValue in model.updateAppState(newValue) }
        .onChange(of: model.isRunning) { _, running in
            if running { path.append(.processing) }
        }
        .alert("알림", isPresented: Binding(get: { model.alertMessage != nil }, set: { if !$0 { model.alertMessage = nil } })) {
            Button("확인", role: .cancel) { model.alertMessage = nil }
        } message: {
            Text(model.alertMessage ?? "")
        }
    }

    private func findResult(_ id: UUID) -> OCRImageResult? {
        if let result = model.currentExperiment?.results.first(where: { $0.id == id }) { return result }
        return model.experiments.flatMap(\.results).first { $0.id == id }
    }
}

