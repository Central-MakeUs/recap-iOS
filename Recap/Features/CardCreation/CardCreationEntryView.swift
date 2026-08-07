import SwiftUI

struct CardCreationEntryView: View {
    let onAction: (CardCreationAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: 96)

            VStack(spacing: 24) {
                CardCreationFolderIllustration(style: .ready)

                VStack(spacing: 9) {
                    Text("스크린샷을 정리해볼까요?")
                        .font(RecapFont.pretendard(size: 22, weight: .semibold))
                        .tracking(-0.44)
                        .foregroundStyle(Color.recapGray900)

                    Text("갤러리에서 스크린샷을 선택하면\nRE-CAP이 정보 카드로 정리해드려요.")
                        .font(RecapFont.pretendard(size: 14, weight: .medium))
                        .tracking(-0.28)
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.recapGray500)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            RecapButton(title: "스크린샷 선택하기", style: .primary, action: start)
                .padding(.horizontal, 16)
                .padding(.bottom, 31)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Text("정리하기")
                .font(RecapFont.pretendard(size: 22, weight: .semibold))
                .tracking(-0.44)
                .foregroundStyle(Color.recapGray900)
            Spacer()
            Button(action: openSettings) {
                RecapIconView(icon: .more, size: 24, color: Color.recapGray900)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .frame(height: 64, alignment: .top)
    }

    private func start() { onAction(.start) }
    private func openSettings() { onAction(.openSettings) }
}

#Preview("CardCreation entry") {
    CardCreationEntryView(onAction: PreviewActions.handleCardCreation)
}
