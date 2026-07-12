import SwiftUI

struct CardCreationResultView: View {
    let state: CardCreationResultState
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
                    CardCreationFolderIllustration(style: .complete)
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

struct CardCreationUnavailableView: View {
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
                CardCreationDashedIcon(
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

