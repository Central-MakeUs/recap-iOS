import Observation
import SwiftUI

struct CardCreationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CardCreationFlowViewModel
    @State private var isPhotoPickerPresented = false
    @State private var isAppendingSelection = false

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
            case .confirmation:
                SelectedScreenshotsConfirmationView(
                    screenshots: viewModel.selectedScreenshots,
                    isSubmitting: false,
                    message: viewModel.failedLoadCount > 0
                        ? "\(viewModel.failedLoadCount)장의 이미지를 불러오지 못했어요."
                        : nil,
                    toastMessage: nil,
                    onBack: close,
                    onAdd: presentAdditionalPicker,
                    onRemove: viewModel.removeScreenshot,
                    onConfirm: viewModel.beginProcessing
                )
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
                maxSelectionCount: max(1, 20 - (isAppendingSelection ? viewModel.selectedCount : 0)),
                onLoad: handleLoadedScreenshots,
                onCancel: handlePickerCancellation
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
        viewModel.receivePickerSelection(
            imageData: imageData,
            failedCount: failedCount,
            appending: isAppendingSelection
        )
        isAppendingSelection = false
    }

    private func presentAdditionalPicker() {
        guard viewModel.selectedCount < 20 else { return }
        isAppendingSelection = true
        isPhotoPickerPresented = true
    }

    private func handlePickerCancellation() {
        if isAppendingSelection {
            isAppendingSelection = false
        } else {
            close()
        }
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
