import SwiftUI

struct ShareSetupMockup: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.recapControlFill)
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
                    ShareAppIconRow(spacing: 20)
                        .offset(y: 62)
                }
        }
    }
}

struct ShareSetupTutorialFrame: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.recapGray900)
                .frame(width: 343, height: 478)

            ShareSheetTutorialMockup()
                .frame(width: 220, height: 477)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            TutorialFrameArrows()
                .padding(.horizontal, 7)
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
                        .foregroundStyle(Color.recapGray300)
                }

            ShareAppIconRow(spacing: 13)
                .padding(.top, 6)

            Spacer()
        }
        .padding(.top, 46)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

private struct ShareAppIconRow: View {
    let spacing: CGFloat

    var body: some View {
        HStack(spacing: spacing) {
            ShareAppIcon(title: "이미지", systemName: "photo.fill")
            ShareAppIcon(title: "Recap", systemName: "r.square.fill", highlighted: true)
            ShareAppIcon(title: "더보기", systemName: "ellipsis")
        }
    }
}

private struct ShareAppIcon: View {
    let title: String
    let systemName: String
    var highlighted = false

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(highlighted ? Color.recapBlue300 : Color.recapGray100)
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: systemName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(highlighted ? .white : Color.recapGray500)
                }

            Text(title)
                .font(RecapFont.pretendard(size: 8, weight: .medium))
                .tracking(-0.16)
                .foregroundStyle(highlighted ? Color.recapGray900 : Color.recapGray500)
        }
    }
}

private struct TutorialFrameArrows: View {
    var body: some View {
        HStack {
            RecapIconView(icon: .back, size: 24, color: .white)

            Spacer()

            RecapIconView(icon: .back, size: 24, color: .white)
                .rotationEffect(.degrees(180))
        }
    }
}

struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(RecapFont.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(Color.recapBlue300)
            .padding(.horizontal, 15)
            .frame(height: 41)
            .background(.white)
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(Color.recapBlue300, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
    }
}
