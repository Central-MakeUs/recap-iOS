import SwiftUI

struct RecentRecapCard: View {
    let card: InformationCard

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(width: 111, height: 111)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(card.title)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .lineLimit(1)

                RecapCategoryPill(kind: card.collection)
            }
        }
        .frame(width: 111, alignment: .leading)
    }
}

struct ArchiveListCard: View {
    let card: InformationCard

    var body: some View {
        HStack(spacing: 20) {
            thumbnailGroup

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .lineLimit(1)

                Text(card.summary)
                    .font(RecapFont.pretendard(size: 12, weight: .medium))
                    .tracking(-0.24)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if card.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RecapTheme.ColorToken.primary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 94)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RecapTheme.ColorToken.border)
                .frame(height: 1)
        }
    }

    private var thumbnailGroup: some View {
        ZStack(alignment: .leading) {
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(width: 59, height: 59)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .offset(x: 20)
                .opacity(0.82)
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(width: 59, height: 59)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .frame(width: 79, height: 59, alignment: .leading)
    }
}

struct FavoriteRecapListCard: View {
    let card: InformationCard
    var isStarred = false

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(width: 68, height: 68)
                .fixedSize(horizontal: true, vertical: true)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .padding(.top, 13)

            VStack(alignment: .leading, spacing: 8) {
                RecapCategoryPill(kind: card.collection)

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.title)
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        .lineLimit(1)
                    Text(card.summary)
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.top, 13)

            Spacer(minLength: 0)

            RecapIconView(
                icon: .star,
                size: 22,
                color: isStarred ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.border
            )
            .padding(.top, 10)
        }
        .padding(.horizontal, 16)
        .frame(height: 94, alignment: .top)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RecapTheme.ColorToken.border)
                .frame(height: 1)
        }
    }
}

struct ArchiveOtherCard: View {
    let card: InformationCard

    var body: some View {
        HStack(spacing: 15) {
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(RecapFont.pretendard(size: 14, weight: .semibold))
                    .tracking(-0.28)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .lineLimit(1)
                Text(card.summary)
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .lineLimit(1)
                Text("6월 27일 정리")
                    .font(RecapFont.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textTertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: card.isFavorite ? "star.fill" : "star")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(card.isFavorite ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.border)
                .frame(width: 24, height: 24)
                .alignmentGuide(.top) { _ in 3 }
        }
        .padding(.horizontal, 16)
        .frame(height: 94)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(RecapTheme.ColorToken.border).frame(height: 1)
        }
    }
}

struct RecapSearchResultCard: View {
    let card: InformationCard

    var body: some View {
        HStack(spacing: 15) {
            RecapScreenshotThumbnail(kind: card.collection, assetName: card.thumbnailAssetName)
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                RecapCategoryPill(kind: card.collection)
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.title)
                        .font(RecapFont.pretendard(size: 14, weight: .semibold))
                        .tracking(-0.28)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        .lineLimit(1)
                    Text(card.summary)
                        .font(RecapFont.pretendard(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: card.isFavorite ? "star.fill" : "star")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(card.isFavorite ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.border)
        }
        .padding(.horizontal, 16)
        .frame(height: 94)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(RecapTheme.ColorToken.border).frame(height: 1)
        }
    }
}

struct RecapCategoryPill: View {
    let kind: CollectionKind
    var size: Size = .small

    enum Size {
        case small
        case regular
    }

    var body: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)
        Text(display.title)
            .font(RecapFont.pretendard(size: size == .small ? 10 : 13, weight: .medium))
            .tracking(size == .small ? -0.20 : -0.26)
            .foregroundStyle(display.textColor)
            .padding(.horizontal, 10)
            .frame(height: size == .small ? 22 : 26)
            .overlay {
                Capsule().stroke(display.dotColor, lineWidth: 1)
            }
    }
}

struct RecapScreenshotThumbnail: View {
    let kind: CollectionKind
    var assetName: String? = nil

    var body: some View {
        Group {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .clipped()
        .overlay {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(RecapTheme.ColorToken.border, lineWidth: 1)
        }
    }

    private var placeholder: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)
        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(RecapTheme.ColorToken.thumbnail)
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(display.dotColor.opacity(0.20))
                    .frame(height: 18)
            }
            .overlay {
                Image(systemName: display.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(display.textColor.opacity(0.55))
            }
    }
}

#Preview("Figma cards") {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                RecentRecapCard(card: SampleData.cards[0])
                ArchiveListCard(card: SampleData.cards[1])
                FavoriteRecapListCard(card: SampleData.cards[2], isStarred: true)
                RecapSearchResultCard(card: SampleData.cards[0])
            }
            .padding()
        }
    }
}
