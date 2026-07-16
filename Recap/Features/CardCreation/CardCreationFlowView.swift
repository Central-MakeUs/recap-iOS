import Observation
import SwiftUI

struct CardCreationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CardCreationFlowViewModel

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
            case .selecting:
                CardCreationSelectionView(viewModel: viewModel, onClose: close)
            case .confirming:
                CardCreationConfirmationView(viewModel: viewModel, onBack: viewModel.startSelection)
            case .processing:
                CardCreationProcessingView(
                    onCancel: viewModel.cancelProcessing,
                    onComplete: viewModel.finishProcessing
                )
            case .complete:
                CardCreationResultView(state: .complete, selectedCount: viewModel.selectedCount, failedCount: 0, onDone: close)
            case .partialFailure:
                CardCreationResultView(state: .partialFailure, selectedCount: viewModel.selectedCount, failedCount: viewModel.failedLoadCount, onDone: close)
            case .failure:
                CardCreationResultView(state: .failure, selectedCount: viewModel.selectedCount, failedCount: viewModel.failedLoadCount, onDone: close)
            case .noSelection:
                CardCreationNoSelectionView(viewModel: viewModel, onBack: viewModel.startSelection)
            case .noImages:
                CardCreationUnavailableView(
                    variant: .noImages,
                    primaryAction: viewModel.retryLoad,
                    secondaryAction: close
                )
            case .permissionMissing:
                CardCreationUnavailableView(
                    variant: .permissionMissing,
                    primaryAction: close,
                    secondaryAction: nil
                )
            case .loadFailure:
                CardCreationUnavailableView(
                    variant: .loadFailure,
                    primaryAction: viewModel.retryLoad,
                    secondaryAction: nil
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.recapBackground)
    }

    private func close() { dismiss() }
}


#Preview("CardCreation flow") {
    NavigationStack {
        CardCreationFlowView(
            viewModel: CardCreationFlowViewModel(screenshots: CardCreationSampleData.screenshots)
        )
    }
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

#Preview("CardCreation no selection") {
    CardCreationFlowView(
        viewModel: CardCreationFlowViewModel(
            step: .noSelection,
            selectedIDs: []
        )
    )
}

#Preview("CardCreation no images") {
    CardCreationFlowView(
        viewModel: CardCreationFlowViewModel(
            step: .noImages,
            screenshots: [],
            selectedIDs: []
        )
    )
}

#Preview("CardCreation permission missing") {
    CardCreationFlowView(
        viewModel: CardCreationFlowViewModel(step: .permissionMissing)
    )
}

#Preview("CardCreation load failure") {
    CardCreationFlowView(
        viewModel: CardCreationFlowViewModel(step: .loadFailure)
    )
}
