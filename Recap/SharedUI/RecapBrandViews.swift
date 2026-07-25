import SwiftUI
struct RecapLogoText: View {
    var size: CGFloat = 23.17

    var body: some View {
        Text("Recap")
            .font(RecapFont.lexend(size: size, weight: .bold))
            .foregroundStyle(Color.recapBlue300)
            .fixedSize()
    }
}
struct RecapMascotMark: View {
    var size: CGFloat = 127

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.072, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.recapBrandBlue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 0.76)
                .shadow(color: Color.recapBlue300.opacity(0.24), radius: size * 0.18, y: size * 0.07)

            RoundedRectangle(cornerRadius: size * 0.045, style: .continuous)
                .fill(Color.recapBrandAccent)
                .frame(width: size * 0.70, height: size * 0.53)
                .offset(y: -size * 0.01)

            HStack(spacing: size * 0.045) {
                eye
                eye
            }
            .offset(y: size * 0.03)
        }
        .frame(width: size, height: size)
    }

    private var eye: some View {
        Circle()
            .fill(Color.recapBrandTrack)
            .overlay {
                Circle()
                    .fill(Color.recapBrandInk)
                    .frame(width: size * 0.17, height: size * 0.17)
                    .offset(x: size * 0.03)
            }
            .frame(width: size * 0.31, height: size * 0.31)
    }
}
