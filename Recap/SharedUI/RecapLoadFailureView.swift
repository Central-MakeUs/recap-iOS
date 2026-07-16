import SwiftUI

struct RecapLoadFailureView: View {
    enum Style {
        case home
        case archive
    }

    let style: Style
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            warningIcon

            Text(style == .home ? "캡처를 불러오지 못했어요" : "보관함을 불러오지 못했어요")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray900)
                .padding(.top, 22)

            Text("네트워크 상태를 확인한 뒤\n다시 시도해주세요")
                .font(RecapFont.pretendard(size: 14, weight: .medium))
                .tracking(-0.28)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, 10)

            Button(action: retry) {
                Label(style == .home ? "다시 시도" : "다시 불러오기", systemImage: style == .archive ? "arrow.clockwise" : "arrow.clockwise")
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .foregroundStyle(style == .home ? Color.recapBlue300 : .white)
                    .frame(width: style == .home ? 153 : 172, height: 52)
                    .background(style == .archive ? Color.recapBlue300 : Color.clear)
                    .overlay {
                        if style == .home {
                            RoundedRectangle(cornerRadius: 10).stroke(Color.recapBlue300, lineWidth: 1.5)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var warningIcon: some View {
        if style == .home {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.red.opacity(0.08))
                .frame(width: 84, height: 84)
                .overlay {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Color.red)
                }
        } else {
            Circle()
                .fill(Color.recapControlFill)
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
    }
}

#Preview("Home load failure") {
    RecapLoadFailureView(style: .home, retry: {})
}

#Preview("Archive load failure") {
    RecapLoadFailureView(style: .archive, retry: {})
}
