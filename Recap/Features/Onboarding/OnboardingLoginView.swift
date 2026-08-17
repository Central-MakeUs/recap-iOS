import SwiftUI

struct OnboardingLoginView: View {
    enum Provider {
        case kakao
        case apple
    }

    @Environment(\.openURL) private var openURL
    @State private var isLoggingIn = false
    @State private var showsLoginFailure = false

    let onStart: () -> Void
    var login: (Provider) async -> LoginAttemptOutcome = { _ in .success }

    var body: some View {
        OnboardingDesignCanvas {
            loginDecorations

            RecapLogoText(size: 48)
                .onboardingFrame(x: 111, y: 194, width: 153, height: 47)

            title
                .onboardingFrame(x: 105, y: 263, width: 165, height: 50)

            RecapSpeechBubble(text: "5초만에 시작하기")
                .onboardingFrame(x: 117, y: 475, width: 143, height: 46)

            loginDivider

            providerButtons

            terms

            if showsLoginFailure {
                RecapToast(
                        style: RecapToastMessage.loginFailed.content.style,
                        message: RecapToastMessage.loginFailed.content.message
                    )
                    .onboardingFrame(x: 29, y: 717, width: 317, height: 45)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .disabled(isLoggingIn)
        .animation(.easeInOut(duration: 0.2), value: showsLoginFailure)
    }

    private var title: some View {
        Text(
            "\(Text("내 앨범에 쌓인 ").foregroundStyle(Color.recapBlue300))\(Text("스크린샷\n핵심정보만 정리해요").foregroundStyle(Color.recapGray900))"
        )
            .font(RecapFont.pretendard(size: 18, weight: .semibold))
            .tracking(-0.36)
            .lineSpacing(0)
            .multilineTextAlignment(.center)
    }

    private var loginDivider: some View {
        HStack(spacing: 11) {
            Rectangle()
                .fill(Color.recapGray100)
                .frame(width: 68, height: 1)

            Text("간편로그인")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapGray500)

            Rectangle()
                .fill(Color.recapGray100)
                .frame(width: 68, height: 1)
        }
        .onboardingFrame(x: 81, y: 538, width: 213, height: 18)
    }

    private var providerButtons: some View {
        HStack(spacing: 27) {
            Button { authenticate(with: .kakao) } label: {
                Image("OnboardingKakaoLoginButton")
                    .resizable()
                    .frame(width: 67, height: 67)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("카카오 로그인")

            Button { authenticate(with: .apple) } label: {
                Image("OnboardingAppleLoginButton")
                    .resizable()
                    .frame(width: 67, height: 67)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Apple 로그인")
        }
        .onboardingFrame(x: 107, y: 585, width: 161, height: 67)
    }

    private var terms: some View {
        VStack(spacing: 45) {
            HStack(spacing: 10) {
                Button(RecapExternalLink.termsOfService.title) {
                    openURL(RecapExternalLink.termsOfService.url)
                }
                Rectangle()
                    .fill(Color.recapGray100)
                    .frame(width: 1, height: 15)
                Button(RecapExternalLink.privacyPolicy.title) {
                    openURL(RecapExternalLink.privacyPolicy.url)
                }
            }
            .font(RecapFont.pretendard(size: 14, weight: .medium))
            .tracking(0.28)
            .foregroundStyle(Color.recapGray500)

            Text("로그인 시 만 14세 이상이며 이용약관 및\n개인정보 처리방침에 동의하는 것으로 간주됩니다")
                .font(RecapFont.pretendard(size: 12, weight: .medium))
                .tracking(-0.24)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray300)
        }
        .buttonStyle(.plain)
        .onboardingFrame(x: 25, y: 697, width: 326, height: 97, alignment: .top)
    }

    private var loginDecorations: some View {
        OnboardingBackgroundDecorations()
        .onboardingFrame(x: 0, y: 0, width: 375, height: 812)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func authenticate(with provider: Provider) {
        guard !isLoggingIn else { return }
        isLoggingIn = true
        showsLoginFailure = false

        Task {
            let outcome = await login(provider)
            await MainActor.run {
                isLoggingIn = false
                switch outcome {
                case .success:
                    onStart()
                case .failure:
                    showsLoginFailure = true
                case .cancelled, .ignored:
                    break
                }
            }
        }
    }
}

private struct OnboardingBackgroundDecorations: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            decoration(
                "OnboardingLoginDocumentDecoration",
                x: 330,
                y: 114,
                width: 45,
                height: 70
            )
            decoration(
                "OnboardingLoginStackedDocumentsDecoration",
                x: 0,
                y: 252,
                width: 62,
                height: 97
            )
            decoration(
                "OnboardingLoginSearchDecoration",
                x: 305,
                y: 475,
                width: 70,
                height: 95
            )
            decoration(
                "OnboardingLoginCameraDecoration",
                x: 20,
                y: 645,
                width: 58,
                height: 55
            )
        }
        .frame(width: 375, height: 812)
    }

    private func decoration(
        _ name: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        Image(name)
            .resizable()
            .frame(width: width, height: height)
            .position(x: x + width / 2, y: y + height / 2)
    }
}

#if DEBUG
#Preview("Onboarding login") {
    OnboardingLoginView(onStart: {})
}

#Preview("Onboarding login failure") {
    OnboardingLoginView(onStart: {}, login: { _ in .failure })
}
#endif
