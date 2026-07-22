import SwiftUI
import UIKit

extension EnvironmentValues {
    @Entry var recapLogout: () -> Void = {}
}

struct SettingsContainerView: View {
    @Environment(RecapCardStore.self) private var cardStore
    @Environment(\.dismiss) private var dismiss
    @State private var path: [SettingsRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            SettingsView(
                captureCount: cardStore.allCards().count,
                onClose: { dismiss() },
                onNavigate: { path.append($0) }
            )
            .navigationDestination(for: SettingsRoute.self) { route in
                SettingsDetailView(route: route)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    let captureCount: Int
    let onClose: () -> Void
    let onNavigate: (SettingsRoute) -> Void

    init(
        captureCount: Int = 0,
        onClose: @escaping () -> Void = {},
        onNavigate: @escaping (SettingsRoute) -> Void = { _ in }
    ) {
        self.captureCount = captureCount
        self.onClose = onClose
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsHeader(title: "설정", trailingSystemName: "xmark", trailingAction: onClose)
                    .padding(.top, 14)

                VStack(alignment: .leading, spacing: 18) {
                    accountSection
                    permissionSection
                    dataSection
                    privacySection
                    supportSection
                }
                .padding(.top, 30)
            }
            .padding(.horizontal, 23)
            .padding(.bottom, 24)
        }
        .background(Color.settingsBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var accountSection: some View {
        SettingsSection(title: "계정") {
            VStack(spacing: 0) {
                SettingsAccountSummaryRow()

                SettingsDivider()

                SettingsNavigationRow(title: "계정 관리") { onNavigate(.accountManagement) }
            }
            .recapCard(radius: 13, borderColor: Color.recapGray100)
            .contentShape(Rectangle())
            .onTapGesture { onNavigate(.accountManagement) }
        }
    }

    private var permissionSection: some View {
        SettingsSection(title: "이용 및 권한") {
            VStack(spacing: 0) {
                SettingsNavigationRow(title: "이용 안내") { onNavigate(.usageGuide) }

                SettingsDivider()

                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("사진 접근 권한")
                            .font(SettingsTypography.rowTitle)
                            .foregroundStyle(Color.settingsTextPrimary)
                        HStack(spacing: 0) {
                            Text("현재 상태: ")
                                .foregroundStyle(Color.settingsTextSecondary)
                            Text("허용됨")
                                .foregroundStyle(Color.settingsSuccess)
                        }
                        .font(SettingsTypography.rowCaption)
                    }

                    Spacer()

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("설정으로 이동")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(RecapFont.pretendard(size: 12, weight: .semibold))
                        .foregroundStyle(Color.recapBlue300)
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 58)
                .padding(.horizontal, 15)
            }
            .recapCard(radius: 13, borderColor: Color.recapGray100)
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "데이터 관리") {
            VStack(spacing: 0) {
                HStack {
                    Text("정리된 캡처 수")
                        .font(SettingsTypography.rowTitle)
                        .foregroundStyle(Color.settingsTextPrimary)

                    Spacer()

                    Text("\(captureCount)개")
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .foregroundStyle(Color.settingsTextSecondary)
                }
                .frame(height: 43)
                .padding(.horizontal, 15)

                SettingsDivider()

                SettingsNavigationRow(title: "데이터 관리") { onNavigate(.dataManagement) }
            }
            .recapCard(radius: 13, borderColor: Color.recapGray100)
        }
    }

    private var privacySection: some View {
        SettingsSection(title: "개인정보") {
            SettingsNavigationRow(title: "개인정보 처리 안내") { onNavigate(.privacyPolicy) }
            .recapCard(radius: 13, borderColor: Color.recapGray100)
        }
    }

    private var supportSection: some View {
        SettingsSection(title: "고객 지원") {
            Button {
                if let url = URL(string: "mailto:support@recap.app?subject=%5BRecap%20%EB%AC%B8%EC%9D%98%5D") {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 10) {
                    Text("문의하기")
                        .font(SettingsTypography.rowTitle)
                        .foregroundStyle(Color.settingsTextPrimary)

                    Spacer()

                    Text("오류나 이용 중 궁금한 점을 보내주세요")
                        .font(SettingsTypography.rowCaption)
                        .foregroundStyle(Color.settingsTextTertiary)
                        .lineLimit(1)
                }
                .frame(height: 42)
                .padding(.horizontal, 15)
            }
            .buttonStyle(.plain)
            .recapCard(radius: 13, borderColor: Color.recapGray100)
        }
    }

}


#Preview {
    NavigationStack {
        SettingsView()
    }
}

#Preview("Account management") {
    NavigationStack {
        SettingsDetailView(route: .accountManagement)
    }
}

#Preview("My page") {
    NavigationStack {
        SettingsDetailView(route: .notificationSettings)
    }
}
