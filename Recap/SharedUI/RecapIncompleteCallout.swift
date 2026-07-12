import SwiftUI
struct RecapIncompleteCallout: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text("미완성")
                .font(RecapFont.pretendard(size: 11, weight: .bold))
                .tracking(-0.12)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RecapTheme.ColorToken.unimplemented)
                .clipShape(Capsule())
            Text(title)
                .font(RecapFont.pretendard(size: 15, weight: .semibold))
                .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            Text(message)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
        }
        .padding(18)
        .background(RecapTheme.ColorToken.warningSoft)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RecapTheme.ColorToken.unimplemented, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
