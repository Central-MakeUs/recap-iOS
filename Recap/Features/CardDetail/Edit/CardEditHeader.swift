import SwiftUI

struct CardEditHeader: View {
    let isSaveEnabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Text("스크린샷 정보 수정")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray900)

            Spacer()

            Button("취소", action: onCancel)
                .foregroundStyle(Color.recapGray500)

            Button("완료", action: onSave)
                .foregroundStyle(isSaveEnabled ? Color.recapBlue300 : Color.recapGray200)
                .disabled(!isSaveEnabled)
                .padding(.leading, 20)
        }
        .font(RecapFont.pretendard(size: 15, weight: .medium))
        .tracking(-0.3)
        .buttonStyle(.plain)
        .padding(.horizontal, CardDetailStyle.horizontalPadding)
        .frame(height: 52)
    }
}

#Preview("정보카드 수정 헤더") {
    CardEditHeader(isSaveEnabled: true, onCancel: {}, onSave: {})
}
