import Observation
import SwiftUI

struct CardCreationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AIDataTransferConsentStore.self) private var consentStore
    @State private var viewModel: CardCreationFlowViewModel
    @State private var isPhotoPickerPresented = false
    @State private var isAppendingSelection = false
    @State private var isNotificationPermissionGuidePresented = false
    @State private var isExitConfirmationPresented = false
    @State private var isAIConsentSheetPresented = false
    @State private var consentToast: RecapToastContent?

    @MainActor
    init(viewModel: CardCreationFlowViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

#if DEBUG
    /// 프리뷰 전용. 실제 흐름은 `init(viewModel:)`으로 의존성을 주입받는다.
    @MainActor
    init() {
        _viewModel = State(
            initialValue: CardCreationFlowViewModel(processor: PreviewCardCreationPipeline())
        )
    }
#endif

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
                    onBack: requestExit,
                    onAdd: presentAdditionalPicker,
                    onRemove: viewModel.removeScreenshot,
                    onConfirm: confirmSelection
                )
                .recapToast(consentToast)
            case .processing:
                CardCreationProcessingView(
                    progress: viewModel.progress.fractionCompleted,
                    notificationsEnabled: viewModel.areOrganizeNotificationsEnabled,
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
        .overlay {
            if isNotificationPermissionGuidePresented {
                OrganizeNotificationPermissionModal(
                    onEnableNotifications: enableNotificationsAndBeginProcessing,
                    onContinueWithoutNotifications: continueWithoutNotifications
                )
                .transition(.opacity)
            }
        }
        .recapConfirmationDialog(
            isPresented: $isExitConfirmationPresented,
            title: "정리를 취소할까요?",
            message: "지금 나가면 공유한 스크린샷이\n정리되지 않아요",
            cancelTitle: "계속정리하기",
            confirmTitle: "나가기",
            confirmStyle: .primary,
            onConfirm: close
        )
        .aiDataTransferConsentSheet(
            isPresented: $isAIConsentSheetPresented,
            onConsent: grantConsentAndContinue
        )
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

    private func requestExit() {
        guard viewModel.selectedCount > 0 else {
            close()
            return
        }
        isExitConfirmationPresented = true
    }

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

    private func confirmSelection() {
        Task {
            do {
                try await consentStore.refresh()
            } catch {
                consentToast = RecapToastContent(
                        style: .error,
                        message: "AI 데이터 전송 동의 상태를 확인하지 못했어요."
                    )
                return
            }

            guard consentStore.hasConsented else {
                isAIConsentSheetPresented = true
                return
            }

            consentToast = nil
            await continueAfterConsent()
        }
    }

    private func grantConsentAndContinue() {
        Task {
            do {
                try await consentStore.grantConsent()
                consentToast = nil
                isAIConsentSheetPresented = false
                await continueAfterConsent()
            } catch {
                consentToast = RecapToastContent(
                    style: .error,
                    message: "AI 데이터 전송 동의를 저장하지 못했어요."
                )
                isAIConsentSheetPresented = false
            }
        }
    }

    private func continueAfterConsent() async {
        if await viewModel.shouldPresentNotificationPermissionGuide() {
            withAnimation(.easeOut(duration: 0.2)) {
                isNotificationPermissionGuidePresented = true
            }
        } else {
            viewModel.beginProcessing()
        }
    }

    private func enableNotificationsAndBeginProcessing() {
        dismissNotificationPermissionGuide()
        Task {
            await viewModel.requestNotificationPermission()
            viewModel.beginProcessing()
        }
    }

    private func continueWithoutNotifications() {
        // 끔으로 저장해 다음 정리에서 안내가 다시 뜨지 않게 한다.
        viewModel.declineNotificationPermissionGuide()
        dismissNotificationPermissionGuide()
        viewModel.beginProcessing()
    }

    private func dismissNotificationPermissionGuide() {
        withAnimation(.easeIn(duration: 0.15)) {
            isNotificationPermissionGuidePresented = false
        }
    }
}


#if DEBUG
#Preview("CardCreation processing") {
    CardCreationProcessingView(
        progress: 0.75,
        notificationsEnabled: true,
        onCancel: {}
    )
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
#endif
