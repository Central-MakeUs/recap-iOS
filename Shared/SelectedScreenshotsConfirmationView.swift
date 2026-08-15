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
    private static let gridColumns = Array(
        repeating: GridItem(.fixed(112), spacing: 6),
        count: 3
    )

    let screenshots: [SelectedScreenshot]
    let isSubmitting: Bool
    let message: String?
    let toastMessage: String?
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
        .overlay(alignment: .bottom) {
            if let toastMessage {
                excludedFileToast(message: toastMessage)
                    .padding(.bottom, 66)
            }
        }
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
            .padding(.leading, 13)
            .padding(.trailing, 14)
        }
    }

    private func screenshotTile(for screenshot: SelectedScreenshot) -> some View {
        ZStack(alignment: .topTrailing) {
            ScreenshotDataImage(imageData: screenshot.imageData)
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

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
        .frame(width: 112, height: 112)
    }

    private var addScreenshotTile: some View {
        Button(action: onAdd) {
            Image("RecapIconPlusM")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color("RecapGray300"))
                .frame(width: 24, height: 24)
                .frame(width: 112, height: 112)
                .background(Color("RecapBackground"))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            Color("RecapGray300"),
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

    private func excludedFileToast(message: String) -> some View {
        Text(message)
            .font(.custom("Pretendard-Medium", size: 13))
            .tracking(-0.26)
            .foregroundStyle(.white)
            .frame(width: 205, height: 39)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
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

#Preview("03-02_선택 이미지 확인") {
    SelectedScreenshotsConfirmationView(
        screenshots: previewScreenshots,
        isSubmitting: false,
        message: nil,
        toastMessage: nil,
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
        toastMessage: "이미지가 아닌 파일은 제외했어요",
        onBack: {},
        onAdd: {},
        onRemove: { _ in },
        onConfirm: {}
    )
}

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
