import SwiftUI

struct SettingsContainerView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        SettingsStubView(onAction: handleAction)
    }

    private func handleAction(_ action: SettingsAction) {
        switch action {
        case .open(let route):
            router.navigate(.settingsDetail(route))
        }
    }
}

struct SettingsStubView: View {
    let onAction: (SettingsAction) -> Void

    init(onAction: @escaping (SettingsAction) -> Void) {
        self.onAction = onAction
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                HStack(spacing: RecapTheme.Spacing.medium) {
                    Text("설정")
                        .font(.title3.weight(.black))
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: RecapTheme.Spacing.small) {
                    HStack(spacing: RecapTheme.Spacing.small) {
                        Text("R")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(RecapTheme.ColorToken.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text("RE-CAP")
                            .font(.headline.weight(.black))
                            .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    }
                    Text("설정과 데이터 관리는 다음 단계에서 연결됩니다.")
                        .font(.subheadline)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                }
                .padding(RecapTheme.Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .recapCard()

                VStack(spacing: RecapTheme.Spacing.medium) {
                    ForEach(SettingsRoute.allCases) { route in
                        Button {
                            open(route)
                        } label: {
                            SettingsRow(route: route)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(RecapTheme.Spacing.large)
        }
        .background(RecapTheme.ColorToken.background)
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func open(_ route: SettingsRoute) {
        onAction(.open(route))
    }
}

private struct SettingsRow: View {
    let route: SettingsRoute

    var body: some View {
        let item = RecapPresentation.settingsItem(for: route)

        HStack(spacing: RecapTheme.Spacing.medium) {
            Image(systemName: item.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.primary)
                .frame(width: 34, height: 34)
                .background(RecapTheme.ColorToken.primaryLight)
                .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous))

            Text(item.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
        }
        .padding(RecapTheme.Spacing.medium)
        .recapCard()
    }
}

struct SettingsDetailStubView: View {
    let route: SettingsRoute

    var body: some View {
        let item = RecapPresentation.settingsItem(for: route)

        VStack(spacing: RecapTheme.Spacing.large) {
            Image(systemName: "hammer")
                .font(.title.weight(.bold))
                .foregroundStyle(RecapTheme.ColorToken.primary)
                .frame(width: 64, height: 64)
                .background(RecapTheme.ColorToken.primaryLight)
                .clipShape(RoundedRectangle(cornerRadius: RecapTheme.Radius.large, style: .continuous))

            Text(item.title)
                .font(.title3.weight(.black))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

            Text("첫 와이어프레임 구현에서는 상세 기능을 연결하지 않고 화면 진입만 확인합니다.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .padding(.horizontal, RecapTheme.Spacing.xLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsStubView(onAction: PreviewActions.handleSettings)
    }
}

#Preview("Settings detail") {
    NavigationStack { SettingsDetailStubView(route: .permissions) }
}
