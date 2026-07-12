import SwiftUI

struct ShareSetupGuideView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 68)

            RecapOnboardingDots(activeIndex: 2, count: 4)

            ShareSetupHeroText()
                .padding(.horizontal, 22)
                .padding(.top, 30)

            Spacer(minLength: 36)

            ShareSetupMockup()
                .padding(.horizontal, 16)

            ShareSetupActions(onNext: onNext, onSkip: onSkip)
                .padding(.horizontal, 16)
                .padding(.top, 34)
                .padding(.bottom, 19)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct ShareSetupDetailView: View {
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShareSetupBackButton(action: onBack)
                .padding(.leading, 16)
                .padding(.top, 20)

            Text("공유 즐겨찾기 등록하기")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 28)

            ShareSetupTutorialFrame()
                .frame(maxWidth: .infinity)
                .padding(.top, 19)

            ShareSetupDetailCaption()
                .padding(.horizontal, 16)
                .padding(.top, 32)

            Spacer()

            RecapButton(title: "다음", style: .primary, action: onNext)
                .padding(.horizontal, 16)
                .padding(.bottom, 31)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct FirstCleanupStartView: View {
    let onStart: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 68)

            RecapOnboardingDots(activeIndex: 2, count: 3)

            FirstCleanupHeroText()
                .padding(.horizontal, 22)
                .padding(.top, 30)

            Spacer(minLength: 118)

            FirstCleanupIllustration()
                .frame(maxWidth: .infinity)

            Spacer()

            FirstCleanupActions(onStart: onStart, onSkip: onSkip)
                .padding(.horizontal, 16)
                .padding(.bottom, 19)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ShareSetupHeroText: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            RecapLogoText(size: 20.73)

            Text("리캡을 공유 즐겨찾기에\n추가해주세요")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .lineSpacing(3)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

            Text("스크린샷 공유 시트에서 Recap을 바로 선택할 수 있어요.")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ShareSetupActions: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("어떻게 등록하나요?")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RecapTheme.ColorToken.textBody)
                .overlay(alignment: .top) {
                    SpeechBubble(text: "초간단 30초면 끝나요!")
                        .offset(y: -64)
                }

            RecapButton(title: "다음", style: .primary, action: onNext)

            Button("나중에 하기", action: onSkip)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .buttonStyle(.plain)
        }
    }
}

private struct ShareSetupBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RecapIconView(icon: .back, size: 24, color: RecapTheme.ColorToken.textPrimary)
        }
        .buttonStyle(.plain)
    }
}

private struct ShareSetupDetailCaption: View {
    var body: some View {
        HStack(alignment: .top) {
            Text("❷ 공유 시트가 열리면 앱 목록을 왼쪽으로 넘겨 더보기를 눌러주세요")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .lineSpacing(3)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .frame(width: 262, alignment: .leading)

            Spacer()

            Text("2 / 5")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RecapTheme.ColorToken.textTertiary)
        }
    }
}

private struct FirstCleanupHeroText: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            RecapLogoText(size: 20.73)

            Text("첫 정리를 시작해볼까요?")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)

            Text("쌓아둔 스크린샷을 골라 첫 정리를 시작해보세요!")
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FirstCleanupIllustration: View {
    var body: some View {
        ZStack {
            CleanupCardStack()
                .frame(height: 180)

            RecapMascotMark(size: 126)
                .offset(x: 72, y: -40)
        }
    }
}

private struct FirstCleanupActions: View {
    let onStart: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            RecapButton(title: "스크린샷 선택하기", style: .primary, action: onStart)

            Button("나중에 하기", action: onSkip)
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .buttonStyle(.plain)
        }
    }
}
