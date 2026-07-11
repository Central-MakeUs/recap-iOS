import SwiftUI
import UIKit

extension EnvironmentValues {
    @Entry var recapLogout: () -> Void = {}
}

struct SettingsContainerView: View {
    @Environment(RecapCardStore.self) private var cardStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SettingsView(
            captureCount: cardStore.allCards().count,
            onClose: { dismiss() }
        )
    }
}

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @State private var selectedRoute: SettingsRoute?

    let captureCount: Int
    let onClose: () -> Void

    init(
        captureCount: Int = 0,
        onClose: @escaping () -> Void = {}
    ) {
        self.captureCount = captureCount
        self.onClose = onClose
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
        .background(SettingsColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: Binding(
            get: { selectedRoute != nil },
            set: { if !$0 { selectedRoute = nil } }
        )) {
            if let selectedRoute {
                NavigationStack {
                    SettingsDetailView(route: selectedRoute)
                }
            }
        }
    }

    private var accountSection: some View {
        SettingsSection(title: "계정") {
            VStack(spacing: 0) {
                SettingsAccountSummaryRow(
                    title: "카카오로 로그인 중",
                    subtitle: "recap_user@kakao.com"
                )

                SettingsDivider()

                SettingsNavigationRow(title: "계정 관리") { selectedRoute = .accountManagement }
            }
            .recapCard(radius: 13, borderColor: SettingsColor.cardBorder)
            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .onTapGesture { selectedRoute = .accountManagement }
        }
    }

    private var permissionSection: some View {
        SettingsSection(title: "이용 및 권한") {
            VStack(spacing: 0) {
                SettingsNavigationRow(title: "이용 안내") { selectedRoute = .usageGuide }

                SettingsDivider()

                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("사진 접근 권한")
                            .font(SettingsTypography.rowTitle)
                            .foregroundStyle(SettingsColor.textPrimary)
                        HStack(spacing: 0) {
                            Text("현재 상태: ")
                                .foregroundStyle(SettingsColor.textSecondary)
                            Text("허용됨")
                                .foregroundStyle(SettingsColor.success)
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
                        .foregroundStyle(RecapTheme.ColorToken.primary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 58)
                .padding(.horizontal, 15)
            }
            .recapCard(radius: 13, borderColor: SettingsColor.cardBorder)
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "데이터 관리") {
            VStack(spacing: 0) {
                HStack {
                    Text("정리된 캡처 수")
                        .font(SettingsTypography.rowTitle)
                        .foregroundStyle(SettingsColor.textPrimary)

                    Spacer()

                    Text("\(captureCount)개")
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .foregroundStyle(SettingsColor.textSecondary)
                }
                .frame(height: 43)
                .padding(.horizontal, 15)

                SettingsDivider()

                SettingsNavigationRow(title: "데이터 관리") { selectedRoute = .dataManagement }
            }
            .recapCard(radius: 13, borderColor: SettingsColor.cardBorder)
        }
    }

    private var privacySection: some View {
        SettingsSection(title: "개인정보") {
            SettingsNavigationRow(title: "개인정보 처리 안내") { selectedRoute = .privacyPolicy }
            .recapCard(radius: 13, borderColor: SettingsColor.cardBorder)
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
                        .foregroundStyle(SettingsColor.textPrimary)

                    Spacer()

                    Text("오류나 이용 중 궁금한 점을 보내주세요")
                        .font(SettingsTypography.rowCaption)
                        .foregroundStyle(SettingsColor.textTertiary)
                        .lineLimit(1)
                }
                .frame(height: 42)
                .padding(.horizontal, 15)
            }
            .buttonStyle(.plain)
            .recapCard(radius: 13, borderColor: SettingsColor.cardBorder)
        }
    }

}

struct SettingsDetailView: View {
    let route: SettingsRoute

    var body: some View {
        switch route {
        case .accountManagement:
            AccountManagementView()
        case .notificationSettings:
            MyPageSettingsView()
        case .dataManagement:
            SettingsInformationView(
                title: "데이터 관리",
                rows: [
                    ("정리된 캡처", "42개"),
                    ("원본 이미지", "서버에 저장하지 않음"),
                    ("삭제 범위", "정리 결과와 연결 데이터")
                ],
                note: "데이터 삭제 기능은 삭제 확인 화면에서 다시 한번 확인한 뒤 실행돼요."
            )
        case .usageGuide:
            SettingsInformationView(
                title: "이용 안내",
                rows: [
                    ("선택 업로드", "사용자가 고른 이미지만 정리해요"),
                    ("공유 업로드", "갤러리 공유로 바로 정리할 수 있어요"),
                    ("자동 업로드", "자동 전체 업로드는 하지 않아요")
                ],
                note: "사진 권한은 선택한 스크린샷을 불러오는 용도로만 사용돼요."
            )
        case .privacyPolicy:
            SettingsInformationView(
                title: "개인정보 처리 안내",
                rows: [
                    ("이미지 처리", "정리 요청한 이미지에 한해 처리해요"),
                    ("원본 보관", "원본 이미지는 서버에 저장하지 않아요"),
                    ("민감정보", "정리 전 사용자가 직접 확인할 수 있어요")
                ],
                note: "정리 결과는 앱 안에서 확인하고 필요할 때 삭제할 수 있어요."
            )
        case .support:
            SettingsInformationView(
                title: "문의하기",
                rows: [
                    ("메일", "support@recap.app"),
                    ("제목", "[Recap 문의]"),
                    ("포함 정보", "앱 버전, 기기, OS, 문의 내용")
                ],
                note: "메일 앱을 열 수 없으면 support@recap.app 으로 직접 문의해주세요."
            )
        }
    }
}

private struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.recapLogout) private var logout
    @State private var confirmation: AccountConfirmation?

    var body: some View {
        VStack(spacing: 0) {
            SettingsHeader(title: "계정 관리", leadingAction: { dismiss() })
                .padding(.horizontal, 23)
                .padding(.top, 14)

            VStack(spacing: 24) {
                SettingsAccountSummaryCard()
                    .padding(.top, 30)

                SettingsActionCard(
                    title: "로그아웃",
                    message: "이 기기에서 Recap 계정이 로그아웃돼요.",
                    action: { confirmation = .logout }
                )

                SettingsActionCard(
                    title: "회원탈퇴",
                    message: "계정과 정리된 캡처 데이터를 삭제해요.",
                    tint: SettingsColor.destructive,
                    borderColor: SettingsColor.destructiveBorder,
                    isDestructive: true,
                    action: { confirmation = .withdraw }
                )
            }
            .padding(.horizontal, 23)

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text("로그아웃해도 정리된 캡처 데이터는 삭제되지 않아요.")
                Text("회원탈퇴 시 계정과 연결된 데이터가 삭제될 수 있어요.")
            }
            .font(SettingsTypography.note)
            .foregroundStyle(SettingsColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 23)
            .padding(.bottom, 30)
        }
        .background(SettingsColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            confirmation?.title ?? "",
            isPresented: Binding(
                get: { confirmation != nil },
                set: { if !$0 { confirmation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let confirmation {
                Button(confirmation.actionTitle, role: .destructive) {
                    self.confirmation = nil
                    logout()
                }
            }
            Button("취소", role: .cancel) { confirmation = nil }
        } message: {
            Text(confirmation?.message ?? "")
        }
    }

    private enum AccountConfirmation {
        case logout
        case withdraw

        var title: String { self == .logout ? "로그아웃할까요?" : "회원탈퇴할까요?" }
        var message: String {
            self == .logout
                ? "현재 기기에서 계정 연결을 종료합니다."
                : "계정과 연결된 데이터가 삭제되며 되돌릴 수 없습니다."
        }
        var actionTitle: String { self == .logout ? "로그아웃" : "회원탈퇴" }
    }
}

private struct MyPageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.recapLogout) private var logout
    @State private var completionNotification = true
    @State private var confirmationNotification = true
    @State private var marketingNotification = false
    @State private var showsLogoutConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsHeader(title: "알림 설정", leadingAction: { dismiss() })
                .padding(.horizontal, 23)
                .padding(.top, 42)

            VStack(alignment: .leading, spacing: 32) {
                SettingsToggleSection(title: "서비스 알림") {
                    SettingsToggleRow(
                        title: "정리 완료 알림",
                        subtitle: "스크린샷 정리가 완료되면 알림을 보내요",
                        isOn: $completionNotification
                    )

                    SettingsToggleRow(
                        title: "확인 필요 알림",
                        subtitle: "확인이 필요한 스크린샷이 생기면 알림을 보내요",
                        isOn: $confirmationNotification
                    )
                }

                Rectangle()
                    .fill(SettingsColor.divider)
                    .frame(height: 2)
                    .padding(.horizontal, -23)

                SettingsToggleSection(title: "마케팅 알림") {
                    SettingsToggleRow(
                        title: "이벤트 · 서비스 소식 알림",
                        subtitle: "업데이트와 혜택 소식을 받아요",
                        isOn: $marketingNotification
                    )
                }
            }
            .padding(.top, 38)
            .padding(.horizontal, 23)

            Spacer()

            Button("로그아웃") { showsLogoutConfirmation = true }
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .foregroundStyle(SettingsColor.link)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 29)
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("로그아웃할까요?", isPresented: $showsLogoutConfirmation, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) { logout() }
            Button("취소", role: .cancel) {}
        }
    }
}

private struct SettingsInformationView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let rows: [(String, String)]
    let note: String

    var body: some View {
        VStack(spacing: 0) {
            SettingsHeader(title: title, leadingAction: { dismiss() })
                .padding(.horizontal, 23)
                .padding(.top, 14)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(row.0)
                            .font(SettingsTypography.rowTitle)
                            .foregroundStyle(SettingsColor.textPrimary)

                        Spacer()

                        Text(row.1)
                            .font(SettingsTypography.rowCaption)
                            .foregroundStyle(SettingsColor.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 15)
                    .frame(minHeight: 52)

                    if index < rows.count - 1 {
                        SettingsDivider()
                    }
                }
            }
            .recapCard(radius: 13, borderColor: SettingsColor.cardBorder)
            .padding(.horizontal, 23)
            .padding(.top, 30)

            Text(note)
                .font(SettingsTypography.note)
                .foregroundStyle(SettingsColor.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 23)
                .padding(.top, 13)

            Spacer()
        }
        .background(SettingsColor.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct SettingsHeader: View {
    let title: String
    var leadingAction: (() -> Void)?
    var trailingSystemName: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        if let leadingAction {
            ZStack {
                Text(title)
                    .font(RecapFont.pretendard(size: 17, weight: .semibold))
                    .foregroundStyle(SettingsColor.textPrimary)
                    .frame(maxWidth: .infinity)

                HStack {
                    Button(action: leadingAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SettingsColor.textSecondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
            .frame(height: 32)
        } else {
            HStack {
                Text(title)
                    .font(RecapFont.pretendard(size: 22, weight: .bold))
                    .foregroundStyle(SettingsColor.textPrimary)

                if let trailingSystemName, let trailingAction {
                    Spacer()

                    Button(action: trailingAction) {
                        Image(systemName: trailingSystemName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SettingsColor.textPrimary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 32)
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(SettingsTypography.sectionTitle)
                .foregroundStyle(SettingsColor.textTertiary)
                .padding(.leading, 1)

            content
        }
    }
}

private struct SettingsAccountSummaryRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 13) {
            KakaoAccountIcon()

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .foregroundStyle(SettingsColor.textPrimary)
                Text(subtitle)
                    .font(SettingsTypography.rowCaption)
                    .foregroundStyle(SettingsColor.textTertiary)
            }

            Spacer()
        }
        .frame(height: 65)
        .padding(.horizontal, 15)
    }
}

private struct SettingsAccountSummaryCard: View {
    var body: some View {
        HStack(spacing: 13) {
            KakaoAccountIcon()

            VStack(alignment: .leading, spacing: 3) {
                Text("Recap 사용자")
                    .font(RecapFont.pretendard(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsColor.textPrimary)
                Text("카카오로 로그인 중")
                    .font(SettingsTypography.rowCaption)
                    .foregroundStyle(SettingsColor.textSecondary)
                Text("recap_user@kakao.com")
                    .font(SettingsTypography.rowCaption)
                    .foregroundStyle(SettingsColor.textTertiary)
            }

            Spacer()
        }
        .frame(height: 80)
        .padding(.horizontal, 15)
        .recapCard(radius: 13, borderColor: SettingsColor.cardBorder)
    }
}

private struct SettingsNavigationRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(SettingsTypography.rowTitle)
                .foregroundStyle(SettingsColor.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SettingsColor.chevron)
        }
        .frame(height: 43)
        .padding(.horizontal, 15)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct SettingsActionCard: View {
    let title: String
    let message: String
    var tint: Color = SettingsColor.textPrimary
    var borderColor: Color = SettingsColor.cardBorder
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(SettingsTypography.rowTitle)
                    .foregroundStyle(tint)
                Text(message)
                    .font(SettingsTypography.rowCaption)
                    .foregroundStyle(isDestructive ? tint.opacity(0.82) : SettingsColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 67)
            .padding(.horizontal, 15)
            .recapCard(radius: 13, borderColor: borderColor)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsToggleSection<Content: View>: View {
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text(title)
                .font(RecapFont.pretendard(size: 13, weight: .regular))
                .foregroundStyle(SettingsColor.textSecondary)

            VStack(spacing: 26) {
                content
            }
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(RecapFont.pretendard(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsColor.textPrimary)
                Text(subtitle)
                    .font(RecapFont.pretendard(size: 12, weight: .regular))
                    .foregroundStyle(SettingsColor.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(RecapTheme.ColorToken.primary)
        }
    }
}

private struct KakaoAccountIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 1, green: 222 / 255, blue: 0))

            Image(systemName: "message.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(red: 24 / 255, green: 24 / 255, blue: 24 / 255))
        }
        .frame(width: 38, height: 38)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(SettingsColor.divider)
            .frame(height: 1)
    }
}

private enum SettingsColor {
    static let background = Color(red: 246 / 255, green: 247 / 255, blue: 251 / 255)
    static let cardBorder = Color(red: 226 / 255, green: 230 / 255, blue: 237 / 255)
    static let divider = Color(red: 231 / 255, green: 234 / 255, blue: 241 / 255)
    static let textPrimary = Color(red: 12 / 255, green: 18 / 255, blue: 31 / 255)
    static let textSecondary = Color(red: 82 / 255, green: 94 / 255, blue: 115 / 255)
    static let textTertiary = Color(red: 148 / 255, green: 157 / 255, blue: 176 / 255)
    static let chevron = Color(red: 151 / 255, green: 160 / 255, blue: 178 / 255)
    static let success = Color(red: 24 / 255, green: 167 / 255, blue: 84 / 255)
    static let destructive = Color(red: 236 / 255, green: 68 / 255, blue: 68 / 255)
    static let destructiveBorder = Color(red: 252 / 255, green: 188 / 255, blue: 188 / 255)
    static let link = Color(red: 70 / 255, green: 83 / 255, blue: 106 / 255)
}

private enum SettingsTypography {
    static let sectionTitle = RecapFont.pretendard(size: 12, weight: .semibold)
    static let rowTitle = RecapFont.pretendard(size: 14, weight: .semibold)
    static let rowCaption = RecapFont.pretendard(size: 12, weight: .medium)
    static let note = RecapFont.pretendard(size: 12, weight: .medium)
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
