import SwiftUI

struct OrganizeContainerView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        OrganizePlaceholderView(onAction: handleAction)
    }

    private func handleAction(_ action: OrganizeAction) {
        switch action {
        case .startSelection:
            router.navigate(.organizeStart)
        case .openSettings:
            router.navigate(.settings)
        }
    }
}

struct OrganizePlaceholderView: View {
    let onAction: (OrganizeAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
            ScreenHeader(
                style: .title("정리하기"),
                onMenuTap: openSettings
            )

            Spacer(minLength: RecapTheme.Spacing.large)

            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.primary)
                    .frame(width: 64, height: 64)
                    .background(RecapTheme.ColorToken.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))

                VStack(alignment: .leading, spacing: RecapTheme.Spacing.small) {
                    Text("스크린샷을 선택해\n정보카드로 정리하기")
                        .font(.title2.weight(.black))
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        .lineSpacing(3)

                    Text("PhotoKit/OCR 연결 전 단계라 실제 선택은 아직 연결하지 않고, 정리하기 흐름의 진입 라우트만 명확히 둡니다.")
                        .font(.subheadline)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                        .lineSpacing(3)
                }

                RecapButton(
                    title: "스크린샷 선택하기",
                    style: .primary,
                    action: startSelection
                )
            }
            .padding(RecapTheme.Spacing.large)
            .recapCard()

            Spacer()
        }
        .padding(RecapTheme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
    }

    private func startSelection() {
        onAction(.startSelection)
    }

    private func openSettings() {
        onAction(.openSettings)
    }
}

struct OrganizeStartPlaceholderView: View {
    var body: some View {
        VStack(spacing: RecapTheme.Spacing.large) {
            Image(systemName: "photo.badge.plus")
                .font(.title.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.primary)
                .frame(width: 64, height: 64)
                .background(RecapTheme.ColorToken.primaryLight)
                .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))

            VStack(spacing: RecapTheme.Spacing.small) {
                Text("스크린샷 선택")
                    .font(.title3.weight(.black))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                Text("실제 이미지 선택과 OCR 처리는 다음 기능 단계에서 연결합니다.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .padding(.horizontal, RecapTheme.Spacing.xLarge)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .navigationTitle("스크린샷 선택")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Organize") {
    OrganizePlaceholderView(onAction: PreviewActions.handleOrganize)
}

#Preview("Organize start") {
    NavigationStack {
        OrganizeStartPlaceholderView()
    }
}
