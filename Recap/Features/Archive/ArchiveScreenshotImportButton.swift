import SwiftUI

struct ArchiveScreenshotImportButton: View {
    let action: () -> Void

    var body: some View {
        Button("스크린샷 불러오기", action: action)
            .font(RecapFont.pretendard(size: 14, weight: .semibold))
            .tracking(-0.28)
            .foregroundStyle(Color.recapBlue300)
            .frame(width: 155, height: 45)
            .background(Color.recapBlue50)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .buttonStyle(.plain)
    }
}

#Preview("스크린샷 불러오기 버튼") {
    ArchiveScreenshotImportButton(action: {})
        .padding()
}
