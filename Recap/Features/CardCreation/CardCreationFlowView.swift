import Observation
import SwiftUI

struct CardCreationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CardCreationFlowViewModel
    @State private var isPhotoPickerPresented = false

    @MainActor
    init(viewModel: CardCreationFlowViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @MainActor
    init() {
        _viewModel = State(initialValue: CardCreationFlowViewModel())
    }

    var body: some View {
        Group {
            switch viewModel.step {
            case .picking:
                Color.recapBackground
            case .processing:
                CardCreationProcessingView(
                    progress: viewModel.progress.fractionCompleted,
                    onCancel: cancelProcessing
                )
                .task {
                    await viewModel.processSelectedScreenshots()
                }
            case .complete:
                CardCreationResultView(
                    state: .complete,
                    selectedCount: viewModel.successCount,
                    failedCount: 0,
                    onDone: close
                )
            case .partialFailure:
                CardCreationResultView(
                    state: .partialFailure,
                    selectedCount: viewModel.successCount,
                    failedCount: viewModel.failedLoadCount,
                    onDone: close
                )
            case .failure:
                CardCreationResultView(
                    state: .failure,
                    selectedCount: 0,
                    failedCount: viewModel.failedLoadCount,
                    onDone: close
                )
            }
        }
        .overlay {
            ScreenshotPhotoPickerPresenter(
                isPresented: $isPhotoPickerPresented,
                maxSelectionCount: 20,
                onLoad: handleLoadedScreenshots,
                onCancel: close
            )
        }
        .onAppear(perform: presentPickerIfNeeded)
        .onChange(of: viewModel.step) { _, step in
            if step == .picking {
                isPhotoPickerPresented = true
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.recapBackground)
    }

    private func close() { dismiss() }

    private func presentPickerIfNeeded() {
        if viewModel.step == .picking {
            isPhotoPickerPresented = true
        }
    }

    private func handleLoadedScreenshots(_ imageData: [Data], failedCount: Int) {
        viewModel.startProcessing(
            imageData: imageData,
            failedCount: failedCount
        )
    }

    private func cancelProcessing() {
        Task {
            await viewModel.cancelProcessing()
        }
    }
}


#Preview("CardCreation processing") {
    CardCreationProcessingView(progress: 0.75, onCancel: {})
}

#Preview("CardCreation complete") {
    CardCreationResultView(state: .complete, onDone: {})
}

#Preview("CardCreation partial failure") {
    CardCreationResultView(state: .partialFailure, onDone: {})
}

#Preview("CardCreation failure") {
    CardCreationResultView(state: .failure, onDone: {})
}
