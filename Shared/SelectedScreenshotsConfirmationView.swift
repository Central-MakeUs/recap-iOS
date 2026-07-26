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
    let screenshots: [SelectedScreenshot]
    let isSubmitting: Bool
    let message: String?
    let onBack: () -> Void
    let onAdd: () -> Void
    let onRemove: (SelectedScreenshot.ID) -> Void
    let onConfirm: () -> Void

    @State private var focusedScreenshotID: SelectedScreenshot.ID?

    private var focusedScreenshot: SelectedScreenshot? {
        screenshots.first(where: { $0.id == focusedScreenshotID }) ?? screenshots.first
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            focusedImage
                .padding(.top, 17)
            thumbnailStrip
                .padding(.top, 23)
            Spacer(minLength: 18)
            statusMessage
            confirmButton
                .padding(.top, message == nil ? 0 : 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 31)
        }
        .background(Color("RecapBackground").ignoresSafeArea())
        .onAppear(perform: selectFirstScreenshotIfNeeded)
        .onChange(of: screenshots) { _, _ in
            selectFirstScreenshotIfNeeded()
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color("RecapGray500"))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Text("선택 스크린샷 확인")
                    .font(.custom("Pretendard-SemiBold", size: 16))
                    .tracking(-0.32)
                    .foregroundStyle(Color("RecapGray900"))

                Text("\(screenshots.count)")
                    .font(.custom("Pretendard-SemiBold", size: 16))
                    .tracking(-0.32)
                    .foregroundStyle(Color("RecapBlue300"))
            }
            .padding(.leading, 14)

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundStyle(Color("RecapGray500"))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(screenshots.count >= 20 || isSubmitting)
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
    }

    @ViewBuilder
    private var focusedImage: some View {
        if let focusedScreenshot {
            ScreenshotDataImage(imageData: focusedScreenshot.imageData)
                .frame(width: 262, height: 449)
                .clipped()
        } else {
            Color("RecapGray100")
                .frame(width: 262, height: 449)
        }
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(screenshots) { screenshot in
                    thumbnail(for: screenshot)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 112)
    }

    private func thumbnail(for screenshot: SelectedScreenshot) -> some View {
        ZStack(alignment: .topTrailing) {
            ScreenshotDataImage(imageData: screenshot.imageData)
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    if focusedScreenshotID == screenshot.id {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color("RecapBlue300"), lineWidth: 2)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedScreenshotID = screenshot.id
                }

            Button {
                onRemove(screenshot.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color("RecapGray300"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(7)
            .disabled(isSubmitting)
        }
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
        Button(action: onConfirm) {
            Group {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("\(screenshots.count)장 정리하기")
                        .font(.custom("Pretendard-SemiBold", size: 14))
                        .tracking(-0.28)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .foregroundStyle(.white)
        .background(screenshots.isEmpty ? Color("RecapGray300") : Color("RecapBlue300"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .buttonStyle(.plain)
        .disabled(screenshots.isEmpty || isSubmitting)
    }

    private func selectFirstScreenshotIfNeeded() {
        guard !screenshots.contains(where: { $0.id == focusedScreenshotID }) else {
            return
        }
        focusedScreenshotID = screenshots.first?.id
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

#Preview("선택 이미지 확인") {
    SelectedScreenshotsConfirmationView(
        screenshots: [
            SelectedScreenshot(imageData: previewImageData(color: .systemBlue)),
            SelectedScreenshot(imageData: previewImageData(color: .systemPink)),
            SelectedScreenshot(imageData: previewImageData(color: .systemGreen))
        ],
        isSubmitting: false,
        message: nil,
        onBack: {},
        onAdd: {},
        onRemove: { _ in },
        onConfirm: {}
    )
}

private func previewImageData(color: UIColor) -> Data {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 262, height: 449))
    return renderer.pngData { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: CGSize(width: 262, height: 449)))
    }
}
