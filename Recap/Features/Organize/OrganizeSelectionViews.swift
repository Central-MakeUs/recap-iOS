import Observation
import SwiftUI

struct OrganizeSelectionView: View {
    @Bindable var viewModel: OrganizeFlowViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OrganizeFlowHeader(
                title: "스크린샷 선택",
                countText: "\(viewModel.selectedCount)",
                leading: .close,
                action: onClose
            )

            PhotoLibraryPicker(maxSelectionCount: 30, onLoad: handleLoadedPhotos) { isLoading in
                Label(isLoading ? "불러오는 중" : "갤러리에서 선택", systemImage: "photo.on.rectangle.angled")
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .foregroundStyle(RecapTheme.ColorToken.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(RecapTheme.ColorToken.primary, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            OrganizeScreenshotGrid(
                screenshots: viewModel.screenshots,
                selectedIDs: viewModel.selectedIDs,
                mode: .select,
                onTap: viewModel.toggle
            )

            Spacer(minLength: 0)

            RecapButton(
                title: "\(viewModel.selectedCount)장 선택 완료",
                style: .primary,
                action: viewModel.confirmSelection
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(RecapTheme.ColorToken.background)
    }

    private func handleLoadedPhotos(_ imageData: [Data], failedCount: Int) {
        let screenshots = imageData.map {
            OrganizeScreenshot(kind: .capture, imageData: $0)
        }
        if screenshots.isEmpty {
            viewModel.failLoadingScreenshots()
        } else {
            viewModel.replaceScreenshots(with: screenshots, failedCount: failedCount)
        }
    }
}

struct OrganizeConfirmationView: View {
    @Bindable var viewModel: OrganizeFlowViewModel
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OrganizeFlowHeader(
                title: "선택 스크린샷 확인",
                countText: "\(viewModel.selectedCount)",
                leading: .back,
                action: onBack
            )

            OrganizeScreenshotGrid(
                screenshots: viewModel.selectedScreenshots,
                selectedIDs: viewModel.selectedIDs,
                mode: .confirm,
                onTap: viewModel.remove
            )
            .padding(.top, 8)

            Spacer(minLength: 0)

            RecapButton(
                title: "\(viewModel.selectedCount)장 정리하기",
                style: .primary,
                action: viewModel.startProcessing
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(RecapTheme.ColorToken.background)
    }
}

struct OrganizeNoSelectionView: View {
    @Bindable var viewModel: OrganizeFlowViewModel
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OrganizeFlowHeader(
                title: "선택 이미지 확인",
                countText: "0장",
                leading: .back,
                action: onBack
            )

            Spacer(minLength: 58)

            VStack(spacing: 18) {
                OrganizeDashedIcon(systemName: "plus", tint: RecapTheme.ColorToken.textTertiary)

                VStack(spacing: 9) {
                    Text("선택된 이미지가 없어요")
                        .font(RecapFont.pretendard(size: 18, weight: .semibold))
                        .tracking(-0.36)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                    Text("정리할 스크린샷을 1장 이상\n선택해주세요.")
                        .font(RecapFont.pretendard(size: 14, weight: .medium))
                        .tracking(-0.28)
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)

                    Text("이미지를 제외해도 원본 사진은\n삭제되지 않아요.")
                        .font(RecapFont.pretendard(size: 12, weight: .medium))
                        .tracking(-0.24)
                        .lineSpacing(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                        .padding(.top, 6)
                }
            }

            Spacer()

            VStack(spacing: 9) {
                RecapButton(title: "사진 더 추가", style: .secondary, action: viewModel.addMore)
                DisabledRecapButton(title: "정리 시작하기")
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 24)
        }
        .background(RecapTheme.ColorToken.background)
    }
}

struct OrganizeProcessingView: View {
    let onCancel: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 126)

            VStack(spacing: 22) {
                VStack(alignment: .trailing, spacing: 26) {
                    Text("캐릭터 애니메이션")
                        .font(RecapFont.pretendard(size: 12, weight: .medium))
                        .tracking(-0.24)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                    OrganizeSpeechBubble(text: "앱을 종료해도 백그라운드에서\n정리가 계속 진행돼요!")

                    OrganizeFolderIllustration(style: .searching)
                        .frame(height: 104)
                }

                ProgressView(value: 0.75)
                    .tint(RecapTheme.ColorToken.primary)
                    .padding(.horizontal, 30)

                VStack(spacing: 9) {
                    Text("스크린샷을 분석 · 정리 하고있어요")
                        .font(RecapFont.pretendard(size: 18, weight: .semibold))
                        .tracking(-0.36)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                    Text("정리가 끝나면 바로 알려드릴게요!")
                        .font(RecapFont.pretendard(size: 15, weight: .medium))
                        .tracking(-0.3)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                }
            }

            Spacer()

            RecapButton(title: "정리 취소", style: .secondary, action: onCancel)
                .padding(.horizontal, 16)
                .padding(.bottom, 31)
        }
        .background(RecapTheme.ColorToken.background)
        .task {
            do {
                try await Task.sleep(for: .seconds(1.2))
            } catch {
                return
            }
            onComplete()
        }
    }
}
