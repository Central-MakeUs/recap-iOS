import Observation
import SwiftUI

struct OrganizeFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: OrganizeFlowViewModel

    @MainActor
    init(viewModel: OrganizeFlowViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @MainActor
    init() {
        _viewModel = State(initialValue: OrganizeFlowViewModel())
    }

    var body: some View {
        Group {
            switch viewModel.step {
            case .selecting:
                OrganizeSelectionView(viewModel: viewModel, onClose: close)
            case .confirming:
                OrganizeConfirmationView(viewModel: viewModel, onBack: viewModel.startSelection)
            case .processing:
                OrganizeProcessingView(
                    onCancel: viewModel.cancelProcessing,
                    onComplete: viewModel.finishProcessing
                )
            case .complete:
                OrganizeResultView(state: .complete, selectedCount: viewModel.selectedCount, failedCount: 0, onDone: close)
            case .partialFailure:
                OrganizeResultView(state: .partialFailure, selectedCount: viewModel.selectedCount, failedCount: viewModel.failedLoadCount, onDone: close)
            case .failure:
                OrganizeResultView(state: .failure, selectedCount: viewModel.selectedCount, failedCount: viewModel.failedLoadCount, onDone: close)
            case .noSelection:
                OrganizeNoSelectionView(viewModel: viewModel, onBack: viewModel.startSelection)
            case .noImages:
                OrganizeUnavailableView(
                    variant: .noImages,
                    primaryAction: viewModel.retryLoad,
                    secondaryAction: close
                )
            case .permissionMissing:
                OrganizeUnavailableView(
                    variant: .permissionMissing,
                    primaryAction: close,
                    secondaryAction: nil
                )
            case .loadFailure:
                OrganizeUnavailableView(
                    variant: .loadFailure,
                    primaryAction: viewModel.retryLoad,
                    secondaryAction: nil
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(RecapTheme.ColorToken.background)
    }

    private func close() { dismiss() }
}


#Preview("Organize flow") {
    NavigationStack {
        OrganizeFlowView(
            viewModel: OrganizeFlowViewModel(screenshots: OrganizeSampleData.screenshots)
        )
    }
}

#Preview("Organize complete") {
    OrganizeResultView(state: .complete, onDone: {})
}

#Preview("Organize partial failure") {
    OrganizeResultView(state: .partialFailure, onDone: {})
}

#Preview("Organize failure") {
    OrganizeResultView(state: .failure, onDone: {})
}

#Preview("Organize no selection") {
    OrganizeFlowView(
        viewModel: OrganizeFlowViewModel(
            step: .noSelection,
            selectedIDs: []
        )
    )
}

#Preview("Organize no images") {
    OrganizeFlowView(
        viewModel: OrganizeFlowViewModel(
            step: .noImages,
            screenshots: [],
            selectedIDs: []
        )
    )
}

#Preview("Organize permission missing") {
    OrganizeFlowView(
        viewModel: OrganizeFlowViewModel(step: .permissionMissing)
    )
}

#Preview("Organize load failure") {
    OrganizeFlowView(
        viewModel: OrganizeFlowViewModel(step: .loadFailure)
    )
}
