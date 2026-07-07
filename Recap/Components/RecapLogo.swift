import SwiftUI

struct RecapLogo: View {
    var showsSubtitle = false

    var body: some View {
        VStack(spacing: RecapTheme.Spacing.small) {
            HStack(spacing: RecapTheme.Spacing.small) {
                Text("R")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(RecapTheme.ColorToken.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("RE-CAP")
                    .font(.headline.weight(.black))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
            }

            if showsSubtitle {
                Text("SCREENSHOT ORGANIZER")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(RecapTheme.ColorToken.textTertiary)
            }
        }
    }
}

#Preview {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        RecapLogo(showsSubtitle: true)
            .padding()
    }
}
