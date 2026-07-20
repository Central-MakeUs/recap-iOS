import SwiftUI

struct CollectionHomeEmptyState: View {
    let onImportScreenshots: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RecapArchiveEmptyIllustration()

            Text("아직 정리된 스크린샷이 없어요")
                .font(RecapFont.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 20)

            Text("정리할 스크린샷을 불러오거나\n갤러리에서 공유해주세요")
                .font(RecapFont.pretendard(size: 14, weight: .regular))
                .tracking(-0.28)
                .lineSpacing(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapGray300)
                .padding(.top, 13)

            ArchiveScreenshotImportButton(action: onImportScreenshots)
                .padding(.top, 23)
        }
    }
}

#Preview("보관함 빈 상태") {
    CollectionHomeEmptyState(onImportScreenshots: {})
        .padding()
}
