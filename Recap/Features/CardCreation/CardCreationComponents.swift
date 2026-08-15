import SwiftUI

struct CardCreationScreenshotGrid: View {
    enum Mode {
        case select
        case confirm
    }

    let screenshots: [CardCreationScreenshot]
    let selectedIDs: Set<CardCreationScreenshot.ID>
    let mode: Mode
    let onTap: (CardCreationScreenshot) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: mode == .select ? 0 : 8) {
            ForEach(screenshots) { screenshot in
                Button {
                    onTap(screenshot)
                } label: {
                    CardCreationScreenshotCell(
                        screenshot: screenshot,
                        isSelected: selectedIDs.contains(screenshot.id),
                        mode: mode
                    )
                }
                .buttonStyle(.plain)
            }

            if mode == .confirm {
                CardCreationAddSlotCell()
            }
        }
        .padding(.horizontal, mode == .select ? 0 : 14)
    }
}

struct CardCreationScreenshotCell: View {
    let screenshot: CardCreationScreenshot
    let isSelected: Bool
    let mode: CardCreationScreenshotGrid.Mode

    var body: some View {
        Group {
            if let data = screenshot.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RecapScreenshotThumbnail(kind: screenshot.kind, assetName: screenshot.assetName)
            }
        }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: mode == .select ? 0 : 8, style: .continuous))
            .overlay(alignment: mode == .select ? .center : .topTrailing) {
                if isSelected {
                    selectionBadge
                        .padding(mode == .select ? 0 : 5)
                }
            }
    }

    private var selectionBadge: some View {
        Circle()
            .fill(mode == .select ? Color.recapBlue300 : Color.recapGray300)
            .frame(width: mode == .select ? 18 : 18, height: mode == .select ? 18 : 18)
            .overlay {
                Image(systemName: mode == .select ? "checkmark" : "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

struct CardCreationAddSlotCell: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(
                Color.recapGray300,
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
            .aspectRatio(1, contentMode: .fit)
    }
}

struct CardCreationFolderIllustration: View {
    enum Style {
        case ready
        case searching
        case complete
    }

    let style: Style

    var body: some View {
        ZStack {
            if style == .complete {
                confetti
                    .offset(y: -36)
            }

            if style == .searching {
                VStack(spacing: 7) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.recapGray100.opacity(0.45))
                            .frame(width: 31, height: 31)
                    }
                }
                .offset(x: -42, y: 2)
            }

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.recapBlue300)
                .frame(width: 96, height: 73)
                .offset(x: 8, y: style == .ready ? 0 : 7)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.recapBlue300.opacity(0.75))
                        .frame(width: 45, height: 16)
                        .offset(x: 8, y: -5)
                }

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.recapBlue300.opacity(0.92),
                            Color.recapBlue300.opacity(0.42)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 93, height: 67)
                .offset(x: style == .searching ? 13 : 0, y: 21)

            if style == .searching {
                HStack(spacing: 4) {
                    eye(offset: -3)
                    eye(offset: 3)
                }
                .offset(x: -6, y: 12)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(Color.recapCardCreationAccent)
                    .offset(x: -37, y: 40)
            } else {
                HStack(spacing: 4) {
                    happyEye
                    happyEye
                }
                .offset(y: 22)
            }
        }
        .frame(width: 150, height: style == .ready ? 132 : 150)
    }

    private func eye(offset: CGFloat) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 28, height: 28)
            .overlay {
                Capsule()
                    .fill(Color.recapGray900)
                    .frame(width: 18, height: 6)
                    .offset(x: offset)
            }
    }

    private var happyEye: some View {
        Image(systemName: "chevron.up")
            .font(.system(size: 18, weight: .bold))
            .rotationEffect(.degrees(180))
            .foregroundStyle(.white)
    }

    private var confetti: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(index.isMultiple(of: 2) ? Color.recapBlue300 : Color.recapBlue300.opacity(0.14))
                    .frame(width: 5, height: 14)
                    .rotationEffect(.degrees(Double(index * 28)))
                    .offset(x: CGFloat((index % 4) * 24 - 36), y: CGFloat((index / 4) * 22))
            }
        }
    }
}
