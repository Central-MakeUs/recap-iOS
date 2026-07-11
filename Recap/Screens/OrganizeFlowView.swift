import Observation
import PhotosUI
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

private struct OrganizeSelectionView: View {
    @Bindable var viewModel: OrganizeFlowViewModel
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OrganizeFlowHeader(
                title: "스크린샷 선택",
                countText: "\(viewModel.selectedCount)",
                leading: .close,
                action: onClose
            )

            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: 30,
                matching: .images
            ) {
                Label(isLoadingPhotos ? "불러오는 중" : "갤러리에서 선택", systemImage: "photo.on.rectangle.angled")
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
            .disabled(isLoadingPhotos)
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
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            load(items)
        }
    }

    private func load(_ items: [PhotosPickerItem]) {
        isLoadingPhotos = true
        Task {
            var screenshots: [OrganizeScreenshot] = []
            var failedCount = 0
            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        failedCount += 1
                        continue
                    }
                    screenshots.append(OrganizeScreenshot(kind: .capture, imageData: data))
                } catch {
                    failedCount += 1
                }
            }
            await MainActor.run {
                isLoadingPhotos = false
                if screenshots.isEmpty {
                    viewModel.failLoadingScreenshots()
                } else {
                    viewModel.replaceScreenshots(with: screenshots, failedCount: failedCount)
                }
            }
        }
    }
}

private struct OrganizeConfirmationView: View {
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

private struct OrganizeNoSelectionView: View {
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

private struct OrganizeProcessingView: View {
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

                    SpeechBubble(text: "앱을 종료해도 백그라운드에서\n정리가 계속 진행돼요!")

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

private struct OrganizeResultView: View {
    let state: OrganizeResultState
    var selectedCount = 5
    var failedCount = 1
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 92)

            VStack(spacing: 25) {
                statusIcon

                Text(state.title(selectedCount: selectedCount, failedCount: failedCount))
                    .font(RecapFont.pretendard(size: 20, weight: .semibold))
                    .tracking(-0.4)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                if state == .complete {
                    OrganizeFolderIllustration(style: .complete)
                        .padding(.top, 9)
                }

                Text(state.message)
                    .font(RecapFont.pretendard(size: 15, weight: .medium))
                    .tracking(-0.3)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .padding(.top, state == .complete ? 24 : -8)
            }

            Spacer()

            RecapButton(title: state.buttonTitle, style: .primary, action: onDone)
                .padding(.horizontal, 22)
                .padding(.bottom, 25)
        }
        .background(state == .complete ? RecapTheme.ColorToken.background : RecapTheme.ColorToken.controlFill)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .complete:
            Circle()
                .fill(RecapTheme.ColorToken.primary)
                .frame(width: 22, height: 22)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
        case .partialFailure:
            Circle()
                .fill(Color.white)
                .frame(width: 57, height: 57)
                .overlay {
                    Text("!")
                        .font(RecapFont.pretendard(size: 24, weight: .semibold))
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                }
                .overlay {
                    Circle().stroke(RecapTheme.ColorToken.border, lineWidth: 1)
                }
        case .failure:
            Circle()
                .fill(Color(red: 1, green: 235 / 255, blue: 235 / 255))
                .frame(width: 57, height: 57)
                .overlay {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(red: 235 / 255, green: 70 / 255, blue: 70 / 255))
                }
        }
    }
}

private struct OrganizeUnavailableView: View {
    enum Variant {
        case noImages
        case permissionMissing
        case loadFailure

        var iconName: String {
            switch self {
            case .noImages: "camera"
            case .permissionMissing: "photo.badge.exclamationmark"
            case .loadFailure: "exclamationmark.triangle"
            }
        }

        var title: String {
            switch self {
            case .noImages:
                "선택할 수 있는 스크린샷이 없어요"
            case .permissionMissing:
                "사진 접근 권한이 꺼져 있어요"
            case .loadFailure:
                "이미지를 불러오지 못했어요"
            }
        }

        var message: String {
            switch self {
            case .noImages:
                "갤러리에 스크린샷을 저장한 뒤\n다시 시도해보세요."
            case .permissionMissing:
                "설정에서 사진 접근 권한을\n허용해주세요."
            case .loadFailure:
                "잠시 후 다시 시도해주세요."
            }
        }

        var primaryTitle: String {
            switch self {
            case .noImages:
                "다시 불러오기"
            case .permissionMissing:
                "설정으로 이동"
            case .loadFailure:
                "다시 시도"
            }
        }
    }

    let variant: Variant
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소", action: secondaryAction ?? primaryAction)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 49)

            Spacer(minLength: 0)

            VStack(spacing: 24) {
                OrganizeDashedIcon(
                    systemName: variant.iconName,
                    tint: variant == .loadFailure ? Color(red: 224 / 255, green: 66 / 255, blue: 66 / 255) : RecapTheme.ColorToken.primary,
                    isError: variant == .loadFailure
                )

                VStack(spacing: 9) {
                    Text(variant.title)
                        .font(RecapFont.pretendard(size: 18, weight: .semibold))
                        .tracking(-0.36)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                    Text(variant.message)
                        .font(RecapFont.pretendard(size: 14, weight: .medium))
                        .tracking(-0.28)
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                }

                RecapButton(
                    title: variant.primaryTitle,
                    style: variant == .loadFailure ? .secondary : .primary,
                    action: primaryAction
                )
                .frame(width: variant == .loadFailure ? 154 : 171)

                if variant == .noImages, let secondaryAction {
                    Button("홈으로", action: secondaryAction)
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                        .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .background(RecapTheme.ColorToken.background)
    }
}

private struct OrganizeFlowHeader: View {
    enum Leading {
        case back
        case close
    }

    let title: String
    let countText: String
    let leading: Leading
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: action) {
                Image(systemName: leading == .back ? "chevron.left" : "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Text(title)
                    .font(RecapFont.pretendard(size: 16, weight: .semibold))
                    .tracking(-0.32)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                Text(countText)
                    .font(RecapFont.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(RecapTheme.ColorToken.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 48)
        .frame(height: 104, alignment: .top)
    }
}

private struct OrganizeScreenshotGrid: View {
    enum Mode {
        case select
        case confirm
    }

    let screenshots: [OrganizeScreenshot]
    let selectedIDs: Set<OrganizeScreenshot.ID>
    let mode: Mode
    let onTap: (OrganizeScreenshot) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: mode == .select ? 0 : 8) {
            ForEach(screenshots) { screenshot in
                Button {
                    onTap(screenshot)
                } label: {
                    OrganizeScreenshotCell(
                        screenshot: screenshot,
                        isSelected: selectedIDs.contains(screenshot.id),
                        mode: mode
                    )
                }
                .buttonStyle(.plain)
            }

            if mode == .confirm {
                OrganizeAddSlotCell()
            }
        }
        .padding(.horizontal, mode == .select ? 0 : 14)
    }
}

private struct OrganizeScreenshotCell: View {
    let screenshot: OrganizeScreenshot
    let isSelected: Bool
    let mode: OrganizeScreenshotGrid.Mode

    var body: some View {
        Group {
            if let data = screenshot.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RecapScreenshotThumbnail(kind: screenshot.kind, assetName: screenshot.assetName)
            }
        }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: mode == .select ? 0 : 8, style: .continuous))
            .overlay(alignment: mode == .select ? .center : .topTrailing) {
                if isSelected {
                    selectionBadge
                        .padding(mode == .select ? 0 : 5)
                }
            }
    }

    private var selectionBadge: some View {
        Circle()
            .fill(mode == .select ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.textTertiary)
            .frame(width: mode == .select ? 18 : 18, height: mode == .select ? 18 : 18)
            .overlay {
                Image(systemName: mode == .select ? "checkmark" : "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

private struct OrganizeAddSlotCell: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(
                RecapTheme.ColorToken.textTertiary,
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
            .aspectRatio(1, contentMode: .fit)
    }
}

struct OrganizeFolderIllustration: View {
    enum Style {
        case ready
        case searching
        case complete
    }

    let style: Style

    var body: some View {
        ZStack {
            if style == .complete {
                confetti
                    .offset(y: -36)
            }

            if style == .searching {
                VStack(spacing: 7) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(RecapTheme.ColorToken.border.opacity(0.45))
                            .frame(width: 31, height: 31)
                    }
                }
                .offset(x: -42, y: 2)
            }

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(RecapTheme.ColorToken.primary)
                .frame(width: 96, height: 73)
                .offset(x: 8, y: style == .ready ? 0 : 7)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(RecapTheme.ColorToken.primary.opacity(0.75))
                        .frame(width: 45, height: 16)
                        .offset(x: 8, y: -5)
                }

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            RecapTheme.ColorToken.primary.opacity(0.92),
                            RecapTheme.ColorToken.primary.opacity(0.42)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 93, height: 67)
                .offset(x: style == .searching ? 13 : 0, y: 21)

            if style == .searching {
                HStack(spacing: 4) {
                    eye(offset: -3)
                    eye(offset: 3)
                }
                .offset(x: -6, y: 12)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(Color(red: 42 / 255, green: 62 / 255, blue: 190 / 255))
                    .offset(x: -37, y: 40)
            } else {
                HStack(spacing: 4) {
                    happyEye
                    happyEye
                }
                .offset(y: 22)
            }
        }
        .frame(width: 150, height: style == .ready ? 132 : 150)
    }

    private func eye(offset: CGFloat) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 28, height: 28)
            .overlay {
                Capsule()
                    .fill(RecapTheme.ColorToken.textPrimary)
                    .frame(width: 18, height: 6)
                    .offset(x: offset)
            }
    }

    private var happyEye: some View {
        Image(systemName: "chevron.up")
            .font(.system(size: 18, weight: .bold))
            .rotationEffect(.degrees(180))
            .foregroundStyle(.white)
    }

    private var confetti: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(index.isMultiple(of: 2) ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.primaryLight)
                    .frame(width: 5, height: 14)
                    .rotationEffect(.degrees(Double(index * 28)))
                    .offset(x: CGFloat((index % 4) * 24 - 36), y: CGFloat((index / 4) * 22))
            }
        }
    }
}

private struct OrganizeDashedIcon: View {
    let systemName: String
    let tint: Color
    var isError = false

    var body: some View {
        RoundedRectangle(cornerRadius: 17, style: .continuous)
            .fill(isError ? Color(red: 1, green: 235 / 255, blue: 235 / 255) : RecapTheme.ColorToken.primarySoft)
            .frame(width: 82, height: 82)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(tint)
            }
            .overlay {
                if systemName == "plus" || systemName == "camera" {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(
                            RecapTheme.ColorToken.border,
                            style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                        )
                }
            }
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(RecapFont.pretendard(size: 12, weight: .medium))
            .tracking(-0.24)
            .lineSpacing(3)
            .multilineTextAlignment(.center)
            .foregroundStyle(RecapTheme.ColorToken.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(RecapTheme.ColorToken.primary, lineWidth: 1)
            }
    }
}

private struct DisabledRecapButton: View {
    let title: String

    var body: some View {
        Text(title)
            .font(RecapFont.pretendard(size: 14, weight: .semibold))
            .tracking(-0.28)
            .foregroundStyle(RecapTheme.ColorToken.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(RecapTheme.ColorToken.border)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
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
