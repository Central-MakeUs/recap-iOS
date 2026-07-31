import SwiftUI

struct UsageGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsShareSetupGuide = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsNavigationHeader(title: "이용 안내", dismiss: { dismiss() })

                UsageGuideShareCard {
                    showsShareSetupGuide = true
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Text("Recap 이용 안내")
                    .font(SettingsTypography.sectionTitle)
                    .foregroundStyle(Color.recapGray500)
                    .frame(height: 40, alignment: .topLeading)
                    .padding(.horizontal, 16)
                    .padding(.top, 37)

                VStack(alignment: .leading, spacing: 41) {
                    UsageGuideItem(
                        icon: .recap(.checkbox),
                        title: "직접 선택한 스크린샷을 정리해요",
                        description: "앨범에서 스크린샷을 직접 선택한 경우에만 정리를 시작해요."
                    )

                    UsageGuideItem(
                        icon: .system("square.and.arrow.up.fill"),
                        title: "공유하기 버튼으로 바로 공유해요",
                        description: "다른 앱이나 앨범에서 공유 버튼을 누르고 Recap을 선택하면\n바로 정리할 수 있어요!"
                    )

                    UsageGuideItem(
                        icon: .system("rectangle.slash.fill"),
                        title: "자동으로 가져가지 않아요",
                        description: "스크린샷을 자동 수집하거나 사진첩을 자동 분석하지 않아요."
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showsShareSetupGuide) {
            ShareSetupDetailView {
                showsShareSetupGuide = false
            }
        }
    }
}

private struct UsageGuideShareCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                Color.recapGray50

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Text("공유 즐겨찾기 등록 방법")
                            .font(RecapFont.pretendard(size: 15, weight: .medium))
                            .foregroundStyle(Color.recapGray900)

                        RecapIconView(icon: .forward, size: 16, color: Color.recapGray300)
                    }

                    Text("공유 시트에서 Recap으로\n빠르게 공유할 수 있어요")
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .foregroundStyle(Color.recapGray500)
                        .multilineTextAlignment(.leading)
                }
                .padding(.leading, 18)
                .padding(.top, 23)

                UsageGuideShareSheetPreview()
                    .frame(width: 125, height: 125)
                    .offset(x: 203, y: 16)
            }
            .frame(height: 115)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct UsageGuideShareSheetPreview: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("OnboardingShareSetupMockup")
                .resizable()
                .frame(width: 125, height: 125)

            Image("OnboardingShareImageIcon")
                .resizable()
                .frame(width: 10, height: 10)
                .position(x: 20, y: 19)

            RecapAppIcon(size: 22, showsName: true)
                .position(x: 20, y: 66)
        }
    }
}

private struct UsageGuideItem: View {
    enum Icon {
        case recap(RecapIcon)
        case system(String)
    }

    let icon: Icon
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                iconView

                Text(title)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .foregroundStyle(Color.recapGray700)
            }
            .frame(height: 20)

            Text(description)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .foregroundStyle(Color.recapGray300)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .recap(let icon):
            RecapIconView(icon: icon, size: 16, color: Color.recapBlue300)
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.recapBlue300)
                .frame(width: 16, height: 16)
        }
    }
}

struct PrivacyInformationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsNavigationHeader(title: "개인정보 처리 안내", dismiss: { dismiss() })

                VStack(alignment: .leading, spacing: 22) {
                    PrivacyInformationSection(
                        title: "이미지 처리 방식",
                        content: """
                        직접 선택하거나 공유한 이미지만 서버로 전송됩니다.
                        전송된 이미지는 AI 분석을 거쳐 제목, 한 줄 요약, 본문이 담긴 정보로 정리됩니다.
                        """
                    )

                    PrivacyInformationSection(
                        title: "AI 처리 안내",
                        content: """
                        선택한 이미지와 이미지에서 추출한 텍스트는 Google LLC의 Gemini API로 전송되어 분석됩니다.
                        전송된 정보는 Google의 AI 모델 학습에 사용되지 않습니다.
                        AI가 생성한 결과는 일부 부정확할 수 있으며, 정보카드에서 직접 수정할 수 있습니다.
                        """
                    )

                    PrivacyInformationSection(
                        title: "원본 이미지 보관",
                        content: """
                        원본 이미지는 미리보기 제공을 위해 서버에 저장됩니다.
                        스크린샷을 삭제하거나 데이터 삭제, 회원탈퇴 시 서버에 저장된 원본 이미지도 함께 삭제됩니다.
                        """
                    )

                    PrivacyInformationSection(
                        title: "민감정보 확인",
                        content: """
                        스크린샷에는 개인 정보 및 금융 정보가 포함될 수 있습니다. 정리 전 민감 정보가 담긴 이미지인지 확인해주세요.
                        정리된 스크린샷과 원본 이미지는 본인 계정에서만 확인 가능합니다.
                        """
                    )

                    PrivacyInformationSection(
                        title: "AI 동의 철회",
                        content: "AI 전송 동의는 설정 > 데이터 관리에서 언제든지 철회할 수 있으며, 철회 시 스크린샷 정리 기능을 사용할 수 없습니다."
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 27)
                .padding(.bottom, 40)

                SettingsSectionDivider()

                VStack(spacing: 0) {
                    SettingsNavigationRow(title: RecapExternalLink.privacyPolicy.title) {
                        openURL(RecapExternalLink.privacyPolicy.url)
                    }
                    SettingsNavigationRow(title: RecapExternalLink.termsOfService.title) {
                        openURL(RecapExternalLink.termsOfService.url)
                    }
                }
                .padding(.horizontal, SettingsLayout.horizontalPadding)
                .padding(.top, 15)
            }
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PrivacyInformationSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title)
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .foregroundStyle(Color.recapGray900)

            Text(content)
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .foregroundStyle(Color.recapGray500)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("이용 안내") {
    NavigationStack {
        UsageGuideView()
    }
}

#Preview("개인정보 처리 안내") {
    NavigationStack {
        PrivacyInformationView()
    }
}
