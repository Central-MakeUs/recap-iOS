import SwiftUI
import UIKit

struct SelectedScreenshot: Identifiable, Hashable, Sendable {
    let id: UUID
    let imageData: Data

    init(id: UUID = UUID(), imageData: Data) {
        self.id = id
        self.imageData = imageData
    }
}

struct SelectedScreenshotsConfirmationView: View {
    private static let maximumScreenshotCount = 20
    /// Figma는 타일을 112 고정으로 그렸지만, 그러면 3열에 348 + 좌우 여백 32로
    /// 380이 필요해 SE(375)에서 셋째 열이 잘린다. 폭을 화면에 맡겨 늘고 줄게 한다.
    private static let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: 6),
        count: 3
    )

    let screenshots: [SelectedScreenshot]
    let isSubmitting: Bool
    let message: String?
    let onBack: () -> Void
    let onAdd: () -> Void
    let onRemove: (SelectedScreenshot.ID) -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 28)

            screenshotGrid
                .padding(.top, 28)

            Spacer(minLength: 22)

            statusMessage

            confirmButton
                .padding(.top, message == nil ? 0 : 8)
                .padding(.horizontal, 16)
        }
        .background(Color("RecapBackground").ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image("RecapIconBack")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color("RecapGray500"))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Text("선택 스크린샷 확인")
                .font(.custom("Pretendard-SemiBold", size: 16))
                .tracking(-0.32)
                .foregroundStyle(Color("RecapGray900"))
                .padding(.leading, 13)

            Text("\(screenshots.count)")
                .font(.custom("Pretendard-SemiBold", size: 16))
                .tracking(-0.32)
                .foregroundStyle(Color("RecapBlue300"))
                .padding(.leading, 10)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 24)
    }

    private var screenshotGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: Self.gridColumns,
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(screenshots) { screenshot in
                    screenshotTile(for: screenshot)
                }

                if screenshots.count < Self.maximumScreenshotCount {
                    addScreenshotTile
                }
            }
            // 헤더·정리 버튼과 같은 여백을 쓴다. 예전 13/14는 112 고정 타일
            // 3열(348)을 375 안에 욱여넣으려고 남긴 값이었다.
            .padding(.horizontal, 16)
        }
    }

    /// 칸의 폭은 그리드가 정하고, 높이는 그 폭을 따라 정사각형이 된다.
    /// 빈 색을 자로 세워 정사각을 만든 뒤 그 위에 내용을 얹는 방식이라,
    /// 안에 든 그림 크기가 칸 크기를 흔들지 않는다.
    private func screenshotTile(for screenshot: SelectedScreenshot) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ScreenshotDataImage(imageData: screenshot.imageData)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            // 흰 스크린샷이 흰 배경에 묻히지 않게 경계를 그린다.
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color("RecapGray100"), lineWidth: 0.5)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    onRemove(screenshot.id)
                } label: {
                    Image("RecapIconCancelCircleM")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color("RecapGray300"))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .padding(7)
                .disabled(isSubmitting)
            }
    }

    private var addScreenshotTile: some View {
        Button(action: onAdd) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image("RecapIconPlusM")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color("RecapGray200"))
                        .frame(width: 24, height: 24)
                }
                .background(Color("RecapBackground"))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            Color("RecapGray200"),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                        )
                }
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }

    @ViewBuilder
    private var statusMessage: some View {
        if let message {
            Text(message)
                .font(.custom("Pretendard-Medium", size: 13))
                .tracking(-0.26)
                .foregroundStyle(Color("RecapDestructiveText"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var confirmButton: some View {
        RecapButton(
            title: "\(screenshots.count)장 정리하기",
            isLoading: isSubmitting,
            action: onConfirm
        )
        .disabled(screenshots.isEmpty || isSubmitting)
    }

}

private struct ScreenshotDataImage: View {
    let imageData: Data

    var body: some View {
        if let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color("RecapGray100")
        }
    }
}

#if DEBUG
#Preview("03-02_선택 이미지 확인") {
    SelectedScreenshotsConfirmationView(
        screenshots: previewScreenshots,
        isSubmitting: false,
        message: nil,
        onBack: {},
        onAdd: {},
        onRemove: { _ in },
        onConfirm: {}
    )
}

#Preview("03-02_선택 이미지 확인 · 비이미지 제외") {
    SelectedScreenshotsConfirmationView(
        screenshots: previewScreenshots,
        isSubmitting: false,
        message: nil,
        onBack: {},
        onAdd: {},
        onRemove: { _ in },
        onConfirm: {}
    )
}
#endif

private var previewScreenshots: [SelectedScreenshot] {
    (0..<5).map { index in
        SelectedScreenshot(imageData: checkerboardImageData(phase: index))
    }
}

private func checkerboardImageData(phase: Int) -> Data {
    let size = CGSize(width: 112, height: 112)
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.pngData { context in
        let tileLength: CGFloat = 14
        let colors = [UIColor.white, UIColor(white: 0.92, alpha: 1)]

        for row in 0..<8 {
            for column in 0..<8 {
                colors[(row + column + phase) % colors.count].setFill()
                context.fill(
                    CGRect(
                        x: CGFloat(column) * tileLength,
                        y: CGFloat(row) * tileLength,
                        width: tileLength,
                        height: tileLength
                    )
                )
            }
        }
    }
}
