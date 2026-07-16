import SwiftUI

struct OnboardingIntroView: View {
    let onStart: () -> Void

    var body: some View {
        OnboardingScaffold {
            Spacer(minLength: 60)

            VStack(spacing: 12) {
                RecapLogoText(size: 20.73)

                Text("갤러리에 쌓인 스크린샷\n핵심정보만 정리해요")
                    .font(RecapFont.pretendard(size: 22, weight: .semibold))
                    .tracking(-0.44)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.recapGray900)

                Text("이제 앨범에서 헤맬 필요 없이,\n바로 찾을 수 있어요!")
                    .font(RecapFont.pretendard(size: 15, weight: .medium))
                    .tracking(-0.3)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.recapGray500)
                    .padding(.top, 2)
            }

            Spacer(minLength: 40)

            RecapMascotMark(size: 168)

            Spacer()

            RecapButton(title: "시작하기", style: .primary, action: onStart)
                .padding(.horizontal, 16)
                .padding(.bottom, 31)
        }
    }
}

struct OnboardingLoginView: View {
    enum Provider { case kakao, apple }

    @State private var isLoggingIn = false
    @State private var showsLoginFailure = false

    let onStart: () -> Void
    var login: (Provider) async -> Bool = { _ in true }

    var body: some View {
        OnboardingScaffold {
            Spacer(minLength: 60)

            VStack(spacing: 12) {
                RecapLogoText(size: 20.73)

                Text("갤러리에 쌓인 스크린샷\n핵심정보만 정리해요")
                    .font(RecapFont.pretendard(size: 22, weight: .semibold))
                    .tracking(-0.44)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.recapGray900)

                Text("5초만에 시작하기")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(Color.recapBlue300)
                    .padding(.horizontal, 14)
                    .frame(height: 35)
                    .overlay {
                        Capsule().stroke(Color.recapBlue300, lineWidth: 1)
                    }
                    .padding(.top, 18)
            }

            Spacer(minLength: 120)

            VStack(spacing: 28) {
                Text("간편로그인")
                    .font(RecapFont.pretendard(size: 15, weight: .medium))
                    .tracking(-0.3)
                    .foregroundStyle(Color.recapGray500)

                HStack(spacing: 18) {
                    Button { authenticate(with: .kakao) } label: {
                        Circle()
                            .fill(Color.recapKakaoYellow)
                            .frame(width: 67, height: 67)
                            .overlay {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(Color.recapGray900)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("카카오 로그인")

                    Button { authenticate(with: .apple) } label: {
                        Circle()
                            .fill(Color.recapGray900)
                            .frame(width: 67, height: 67)
                            .overlay {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 29, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Apple 로그인")
                }

                Text("로그인하면 서비스 이용약관 및 개인정보 처리방침에 동의하게 됩니다.")
                    .font(RecapFont.pretendard(size: 12, weight: .medium))
                    .tracking(-0.24)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.recapGray300)
                    .padding(.horizontal, 40)
            }

            Spacer(minLength: 40)
        }
        .disabled(isLoggingIn)
        .overlay(alignment: .bottom) {
            if showsLoginFailure {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                    Text("로그인에 실패했어요. 잠시 후 다시 시도해주세요.")
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                }
                    .foregroundStyle(.white)
                    .frame(width: 317, height: 60)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.bottom, 103)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsLoginFailure)
    }

    private func authenticate(with provider: Provider) {
        guard !isLoggingIn else { return }
        isLoggingIn = true
        showsLoginFailure = false
        Task {
            let succeeded = await login(provider)
            await MainActor.run {
                isLoggingIn = false
                if succeeded {
                    onStart()
                } else {
                    showsLoginFailure = true
                }
            }
        }
    }
}

private struct OnboardingScaffold<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview("Onboarding intro") {
    OnboardingIntroView(onStart: {})
}

#Preview("Onboarding login") {
    OnboardingLoginView(onStart: {})
}

#Preview("Onboarding login failure") {
    OnboardingLoginView(onStart: {}, login: { _ in false })
}
