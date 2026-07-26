import SwiftUI
import UIKit

extension EnvironmentValues {
    @Entry var recapLogout: () -> Void = {}
}

struct SettingsContainerView: View {
    @Environment(RecapCardStore.self) private var cardStore
    @Environment(\.dismiss) private var dismiss
    @State private var route: SettingsRoute?

    var body: some View {
        SettingsView(
            onClose: { dismiss() },
            onNavigate: { route = $0 }
        )
        .navigationDestination(isPresented: detailPresentation) {
            if let route {
                SettingsDetailView(
                    route: route,
                    captureCount: cardStore.allCards().count
                )
                    .id(route)
            }
        }
    }

    private var detailPresentation: Binding<Bool> {
        Binding(
            get: { route != nil },
            set: { isPresented in
                if !isPresented {
                    route = nil
                }
            }
        )
    }
}

struct SettingsView: View {
    let onClose: () -> Void
    let onNavigate: (SettingsRoute) -> Void

    init(
        onClose: @escaping () -> Void = {},
        onNavigate: @escaping (SettingsRoute) -> Void = { _ in }
    ) {
        self.onClose = onClose
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                SettingsNavigationHeader(title: "설정", dismiss: onClose)

                SettingsAccountSection(onNavigate: onNavigate)
                SettingsSectionDivider()
                SettingsNotificationAndPermissionSection(
                    onNavigate: onNavigate
                )
                SettingsSectionDivider()
                SettingsDataSection(onNavigate: onNavigate)
                SettingsSectionDivider()
                SettingsGuideSection(onNavigate: onNavigate)
                SettingsSectionDivider()
                SettingsSupportSection(
                    onNavigate: onNavigate
                )
            }
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

}

private struct SettingsAccountSection: View {
    let onNavigate: (SettingsRoute) -> Void

    var body: some View {
        SettingsListSection(title: "계정", isFirst: true) {
            SettingsNavigationRow(title: "계정 관리") {
                onNavigate(.accountManagement)
            }
        }
    }
}

private struct SettingsNotificationAndPermissionSection: View {
    let onNavigate: (SettingsRoute) -> Void

    var body: some View {
        SettingsListSection(title: "알림") {
            SettingsNavigationRow(title: "앱 알림 설정") {
                onNavigate(.notificationSettings)
            }
        }
    }
}

private struct SettingsDataSection: View {
    let onNavigate: (SettingsRoute) -> Void

    var body: some View {
        SettingsListSection(title: "데이터") {
            SettingsNavigationRow(title: "데이터 관리") {
                onNavigate(.dataManagement)
            }
        }
    }
}

private struct SettingsGuideSection: View {
    let onNavigate: (SettingsRoute) -> Void

    var body: some View {
        SettingsListSection(title: "안내") {
            VStack(spacing: 0) {
                SettingsNavigationRow(title: "이용 안내") {
                    onNavigate(.usageGuide)
                }
                SettingsNavigationRow(title: "개인정보 처리 안내") {
                    onNavigate(.privacyPolicy)
                }
            }
        }
    }
}

private struct SettingsSupportSection: View {
    let onNavigate: (SettingsRoute) -> Void

    var body: some View {
        SettingsListSection(title: "지원") {
            VStack(spacing: 0) {
                SettingsNavigationRow(title: "문의하기") {
                    onNavigate(.support)
                }
                SettingsNavigationRow(title: "오픈소스 라이선스") {
                    onNavigate(.openSourceLicenses)
                }
            }
        }
    }
}

#Preview("설정") {
    NavigationStack {
        SettingsView()
    }
}
