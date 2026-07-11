import SwiftUI

struct ShareSetupGuideView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 68)

            RecapOnboardingDots(activeIndex: 2, count: 4)

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
            .padding(.horizontal, 22)
            .padding(.top, 30)

            Spacer(minLength: 36)

            ShareSetupMockup()
                .padding(.horizontal, 16)

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
            Button(action: onBack) {
                RecapIconView(icon: .back, size: 24, color: RecapTheme.ColorToken.textPrimary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
            .padding(.top, 20)

            Text("공유 즐겨찾기 등록하기")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 28)

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(RecapTheme.ColorToken.textPrimary)
                    .frame(width: 343, height: 478)

                ShareSheetTutorialMockup()
                    .frame(width: 220, height: 477)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                HStack {
                    RecapIconView(icon: .back, size: 24, color: .white)
                    Spacer()
                    RecapIconView(icon: .back, size: 24, color: .white)
                        .rotationEffect(.degrees(180))
                }
                .padding(.horizontal, 7)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 19)

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
            .padding(.horizontal, 22)
            .padding(.top, 30)

            Spacer(minLength: 118)

            ZStack {
                CleanupCardStack()
                    .frame(height: 180)

                RecapMascotMark(size: 126)
                    .offset(x: 72, y: -40)
            }
            .frame(maxWidth: .infinity)

            Spacer()

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
            .padding(.horizontal, 16)
            .padding(.bottom, 19)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RecapTheme.ColorToken.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ShareSetupMockup: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(RecapTheme.ColorToken.controlFill)
                .frame(width: 269, height: 238)
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0), location: 0),
                            .init(color: .white, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 90)
                }
                .overlay(alignment: .center) {
                    HStack(spacing: 20) {
                        ShareAppIcon(title: "이미지", systemName: "photo.fill")
                        ShareAppIcon(title: "Recap", systemName: "r.square.fill", highlighted: true)
                        ShareAppIcon(title: "더보기", systemName: "ellipsis")
                    }
                    .offset(y: 62)
                }
        }
    }
}

private struct ShareSheetTutorialMockup: View {
    var body: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .frame(height: 210)
                .overlay {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(RecapTheme.ColorToken.textTertiary)
                }

            HStack(spacing: 13) {
                ShareAppIcon(title: "이미지", systemName: "photo.fill")
                ShareAppIcon(title: "Recap", systemName: "r.square.fill", highlighted: true)
                ShareAppIcon(title: "더보기", systemName: "ellipsis")
            }
            .padding(.top, 6)

            Spacer()
        }
        .padding(.top, 46)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

private struct ShareAppIcon: View {
    let title: String
    let systemName: String
    var highlighted = false

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(highlighted ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.border)
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: systemName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(highlighted ? .white : RecapTheme.ColorToken.textSecondary)
                }
            Text(title)
                .font(RecapFont.pretendard(size: 8, weight: .medium))
                .tracking(-0.16)
                .foregroundStyle(highlighted ? RecapTheme.ColorToken.textPrimary : RecapTheme.ColorToken.textSecondary)
        }
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(RecapTheme.ColorToken.primary)
            .padding(.horizontal, 15)
            .frame(height: 41)
            .background(.white)
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(RecapTheme.ColorToken.primary, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
    }
}

private struct CleanupCardStack: View {
    private let rotations: [Double] = [-8, -2, 6, 12]
    private let xOffsets: [CGFloat] = [-76, -26, 44, 96]
    private let yOffsets: [CGFloat] = [4, 0, 8, 18]

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(RecapTheme.ColorToken.controlFill)
                    .frame(width: index == 1 ? 118 : 112, height: index == 1 ? 151 : 146)
                    .rotationEffect(.degrees(rotations[index]))
                    .offset(x: xOffsets[index], y: yOffsets[index])
            }
        }
    }
}

#Preview("Share setup guide") {
    ShareSetupGuideView(onNext: {}, onSkip: {})
}

#Preview("Share setup detail") {
    ShareSetupDetailView(onBack: {}, onNext: {})
}

#Preview("First cleanup start") {
    FirstCleanupStartView(onStart: {}, onSkip: {})
}
