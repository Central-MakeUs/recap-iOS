import SwiftUI

struct RecapAppIcon: View {
    var size: CGFloat = 50
    var showsName = false

    var body: some View {
        VStack(spacing: 2) {
            Image("OnboardingRecapAppIcon")
                .resizable()
                .frame(width: size, height: size)

            if showsName {
                Text("Recap")
                    .font(RecapFont.pretendard(size: 11, weight: .medium))
                    .foregroundStyle(Color.recapGray900)
                    .fixedSize()
            }
        }
    }
}

#if DEBUG
#Preview("Recap app icon") {
    HStack(spacing: 24) {
        RecapAppIcon()
        RecapAppIcon(showsName: true)
    }
    .padding()
    .background(Color.recapBackground)
}
#endif
