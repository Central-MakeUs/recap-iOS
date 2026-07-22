import SwiftUI

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

struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.recapLogout) private var logout
    @State private var showsLogoutConfirmation = false

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
                    action: { showsLogoutConfirmation = true }
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("회원탈퇴 준비 중")
                        .font(SettingsTypography.rowTitle)
                        .foregroundStyle(Color.settingsTextSecondary)
                    Text("서버의 계정 삭제 계약이 확정되면 제공할 예정이에요.")
                        .font(SettingsTypography.rowCaption)
                        .foregroundStyle(Color.settingsTextTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 67)
                .padding(.horizontal, 15)
                .recapCard(radius: 13, borderColor: Color.recapGray100)
            }
            .padding(.horizontal, 23)

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text("로그아웃해도 정리된 캡처 데이터는 삭제되지 않아요.")
                Text("로그아웃하면 서버 세션과 이 기기의 로그인 정보가 함께 종료돼요.")
            }
            .font(SettingsTypography.note)
            .foregroundStyle(Color.settingsTextTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 23)
            .padding(.bottom, 30)
        }
        .background(Color.settingsBackground)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "로그아웃할까요?",
            isPresented: $showsLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("로그아웃", role: .destructive) {
                logout()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("서버 세션과 현재 기기의 로그인을 종료합니다.")
        }
    }
}

struct MyPageSettingsView: View {
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
                    .fill(Color.settingsDivider)
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
                .foregroundStyle(Color.settingsLink)
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

struct SettingsInformationView: View {
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
                            .foregroundStyle(Color.settingsTextPrimary)

                        Spacer()

                        Text(row.1)
                            .font(SettingsTypography.rowCaption)
                            .foregroundStyle(Color.settingsTextSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 15)
                    .frame(minHeight: 52)

                    if index < rows.count - 1 {
                        SettingsDivider()
                    }
                }
            }
            .recapCard(radius: 13, borderColor: Color.recapGray100)
            .padding(.horizontal, 23)
            .padding(.top, 30)

            Text(note)
                .font(SettingsTypography.note)
                .foregroundStyle(Color.settingsTextTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 23)
                .padding(.top, 13)

            Spacer()
        }
        .background(Color.settingsBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}
