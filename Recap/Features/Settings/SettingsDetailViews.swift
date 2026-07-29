import SwiftUI
import UIKit

struct SettingsDetailView: View {
    let route: SettingsRoute
    let userAccountService: any UserAccountServing
    let accountWithdrawalCompleted: () -> Void
    let accountDataDeleted: () -> Void

    init(
        route: SettingsRoute,
        userAccountService: any UserAccountServing,
        accountWithdrawalCompleted: @escaping () -> Void,
        accountDataDeleted: @escaping () -> Void
    ) {
        self.route = route
        self.userAccountService = userAccountService
        self.accountWithdrawalCompleted = accountWithdrawalCompleted
        self.accountDataDeleted = accountDataDeleted
    }

    var body: some View {
        switch route {
        case .accountManagement:
            AccountManagementView(
                service: userAccountService,
                accountWithdrawalCompleted: accountWithdrawalCompleted
            )
        case .notificationSettings:
            NotificationSettingsView()
        case .dataManagement:
            DataManagementView(
                service: userAccountService,
                accountDataDeleted: accountDataDeleted
            )
        case .usageGuide:
            UsageGuideView()
        case .privacyPolicy:
            PrivacyInformationView()
        case .support:
            SettingsUnavailableView(title: "문의하기")
        case .openSourceLicenses:
            SettingsUnavailableView(title: "오픈소스 라이선스")
        }
    }
}

struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.recapLogout) private var logout
    @State private var model: AccountManagementModel
    @State private var showsLogoutConfirmation = false
    @State private var showsWithdrawalConfirmation = false

    init(
        service: any UserAccountServing,
        accountWithdrawalCompleted: @escaping () -> Void
    ) {
        _model = State(
            initialValue: AccountManagementModel(
                service: service,
                accountWithdrawalCompleted: accountWithdrawalCompleted
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavigationHeader(title: "계정 관리", dismiss: { dismiss() })

            SettingsListSection(title: "로그인 정보", isFirst: true) {
                SettingsAccountProviderRow(
                    providerName: providerName,
                    joinedDateText: joinedDateText,
                    provider: model.accountInfo?.provider
                )
            }
            .padding(.bottom, -SettingsLayout.sectionBottomPadding)

            SettingsSectionDivider()

            SettingsNavigationRow(title: "로그아웃") {
                showsLogoutConfirmation = true
            }
            .padding(.horizontal, SettingsLayout.horizontalPadding)
            .padding(.top, 23)

            Spacer(minLength: 0)

            Button("회원 탈퇴") {
                showsWithdrawalConfirmation = true
            }
            .buttonStyle(.plain)
            .font(SettingsTypography.rowTitle)
            .foregroundStyle(Color.recapDestructive)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await model.loadAccountInfo()
        }
        .recapToast(model.toast)
        .task(id: model.toast) {
            await clearToastIfNeeded()
        }
        .recapConfirmationDialog(
            isPresented: $showsLogoutConfirmation,
            title: "로그아웃할까요?",
            message: "정리된 캡처는 유지되며,\n다시 로그인하면 확인할 수 있어요.",
            cancelTitle: "취소",
            confirmTitle: "로그아웃",
            confirmStyle: .primary,
            onConfirm: logout
        )
        .recapConfirmationDialog(
            isPresented: $showsWithdrawalConfirmation,
            title: "정말 탈퇴할까요?",
            message: "계정과 정리된 모든 스크린샷, 서버에 저장된 원본\n이미지가 삭제되며 복구할 수 없어요.\n기기 앨범의 사진은 삭제되지 않아요.",
            cancelTitle: "취소",
            confirmTitle: "탈퇴하기",
            height: 210,
            onConfirm: {
                Task {
                    await model.withdrawAccount()
                }
            }
        )
    }

    private var providerName: String {
        switch model.accountInfo?.provider {
        case .kakao:
            "카카오로 로그인중"
        case .apple:
            "Apple로 로그인중"
        case nil:
            "로그인 정보 확인 중"
        }
    }

    private var joinedDateText: String {
        guard let createdAt = model.accountInfo?.createdAt else {
            return ""
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: createdAt
        )
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            return ""
        }
        return "\(year).\(month).\(day) 가입"
    }

    private func clearToastIfNeeded() async {
        guard model.toast != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        model.toast = nil
    }
}

struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: DataManagementModel
    @State private var showsDeleteConfirmation = false

    init(
        service: any UserAccountServing,
        accountDataDeleted: @escaping () -> Void
    ) {
        _model = State(
            initialValue: DataManagementModel(
                service: service,
                accountDataDeleted: accountDataDeleted
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavigationHeader(title: "데이터 관리", dismiss: { dismiss() })

            VStack(spacing: 0) {
                dataSummary

                Button("데이터 삭제") {
                    showsDeleteConfirmation = true
                }
                .buttonStyle(.plain)
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .foregroundStyle(Color.recapDestructive)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Color.recapGray50,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .padding(.top, 19)

                dataDeletionNotes
                    .padding(.top, 32)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 21)
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await model.loadDataSummary()
        }
        .recapToast(model.toast)
        .task(id: model.toast) {
            await clearToastIfNeeded()
        }
        .recapConfirmationDialog(
            isPresented: $showsDeleteConfirmation,
            title: "모든 데이터를 삭제할까요?",
            message: "정리된 모든 스크린샷, 서버에 저장된 원본\n이미지가 삭제되며 복구할 수 없어요.\n기기 앨범의 사진은 삭제되지 않아요.",
            cancelTitle: "취소",
            confirmTitle: "삭제하기",
            height: 210,
            onConfirm: {
                Task {
                    await model.deleteAllData()
                }
            }
        )
    }

    private var dataSummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("정리된 스크린샷")
                        .font(RecapFont.pretendard(size: 16, weight: .semibold))
                        .foregroundStyle(Color.recapGray900)

                    Text("\(model.capturedCount)개")
                        .font(RecapFont.pretendard(size: 22, weight: .semibold))
                        .foregroundStyle(Color.recapBlue300)
                }

                Spacer(minLength: 0)

                Image("SettingsDataIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 61, height: 53)
            }

            Text("제목, 요약, 본문 등 정리된 정보와 원본 이미지가 서버에 보관돼요.")
                .font(SettingsTypography.body)
                .foregroundStyle(Color.recapGray500)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 11)
        }
        .padding(20)
        .frame(height: 151, alignment: .top)
        .background(
            Color.recapGray50,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    private var dataDeletionNotes: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("계정은 유지되며, 삭제 후에도 새로운 스크린샷을 정리할 수 있어요.")
            Text("데이터를 삭제하면 정리된 스크린샷 정보와 서버에 저장된 원본 이미지가 모두 삭제되며, 복구할 수 없어요.")
        }
        .font(SettingsTypography.body)
        .foregroundStyle(Color.recapGray300)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func clearToastIfNeeded() async {
        guard model.toast != nil else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        model.toast = nil
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(OrganizeNotificationController.self) private var notifications

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavigationHeader(title: "알림 설정", dismiss: { dismiss() })

            VStack(spacing: 23) {
                if showsPermissionBanner {
                    SettingsNotificationPermissionBanner(
                        enableNotifications: enableSystemNotifications
                    )
                }

                SettingsNotificationRow(
                    isEnabled: notifications.isEnabled,
                    toggle: toggleOrganizeNotifications
                )
            }
            .padding(.horizontal, SettingsLayout.horizontalPadding)
            .padding(.top, 19)

            Spacer(minLength: 0)
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await refreshSystemNotificationPermission()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }

            Task {
                await refreshSystemNotificationPermission()
            }
        }
    }

    private var showsPermissionBanner: Bool {
        !notifications.authorizationStatus.allowsNotifications
    }

    private func enableSystemNotifications() {
        Task {
            let action = await notifications.enableSystemNotifications()
            if action == .openSettings {
                openSystemSettings()
            }
        }
    }

    private func toggleOrganizeNotifications() {
        Task {
            let action = await notifications.toggleOrganizeNotifications()
            if action == .openSettings {
                openSystemSettings()
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        openURL(url)
    }

    private func refreshSystemNotificationPermission() async {
        await notifications.refreshAuthorization()
    }
}

#Preview("알림 설정") {
    NotificationSettingsView()
        .environment(
            OrganizeNotificationController(
                delivery: PreviewOrganizeNotificationDelivery(),
                userDefaults: UserDefaults(suiteName: UUID().uuidString)!
            )
        )
}

#Preview("계정 관리") {
    AccountManagementView(
        service: PreviewUserAccountService(provider: .apple),
        accountWithdrawalCompleted: {}
    )
}

#Preview("데이터 관리") {
    DataManagementView(
        service: PreviewUserAccountService(),
        accountDataDeleted: {}
    )
}
