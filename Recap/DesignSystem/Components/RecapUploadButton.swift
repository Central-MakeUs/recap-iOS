import SwiftUI

struct RecapUploadButton: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            Image("RecapUploadIcon")
                .resizable()
                .frame(width: 24, height: 24)

            Text("업로드")
                .font(RecapFont.pretendard(size: 14, weight: .semibold))
                .tracking(-0.28)
        }
        .foregroundStyle(.white)
        .frame(
            width: RecapMainTabBarMetrics.uploadButtonSize.width,
            height: RecapMainTabBarMetrics.uploadButtonSize.height
        )
        .background {
            Capsule()
                .fill(Color.recapBrandBlue)
        }
        .contentShape(Capsule())
        .clipShape(Capsule())
        .compositingGroup()
        .opacity(1)
        .onTapGesture(perform: action)
        .accessibilityElement()
        .accessibilityLabel("업로드")
        .accessibilityIdentifier("mainTab.upload")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            action()
        }
    }
}

#Preview("업로드 버튼") {
    RecapUploadButton(action: {})
        .padding()
        .background(Color.recapBackground)
}
