import SwiftUI

struct ArchiveScreenshotImportButton: View {
    let action: () -> Void

    var body: some View {
        RecapButton(
            title: "스크린샷 불러오기",
            style: .secondary,
            size: .medium,
            action: action
        )
        .frame(width: 155)
    }
}

#if DEBUG
#Preview("스크린샷 불러오기 버튼") {
    ArchiveScreenshotImportButton(action: {})
        .padding()
}
#endif
