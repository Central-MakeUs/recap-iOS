import SwiftUI

struct RecentRecapCard: View {
    let card: InformationCard

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            RecapPlaceholderThumbnail(kind: card.collection)
                .frame(width: 111, height: 111)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(card.title)
                    .font(.system(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .lineLimit(1)

                RecapCategoryPill(title: RecapPresentation.collectionDisplay(for: card.collection).title)
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
                    .font(.system(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .lineLimit(1)

                Text(card.summary)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(-0.24)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7)
        .frame(height: 87)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RecapTheme.ColorToken.border)
                .frame(height: 1)
        }
    }

    private var thumbnailGroup: some View {
        ZStack(alignment: .leading) {
            RecapPlaceholderThumbnail(kind: card.collection)
                .frame(width: 59, height: 59)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .offset(x: 20)
            RecapPlaceholderThumbnail(kind: card.collection)
                .frame(width: 59, height: 59)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .frame(width: 79, height: 59, alignment: .leading)
    }
}

struct OrganizeRecapCard: View {
    let card: InformationCard
    var isStarred = false

    var body: some View {
        HStack(spacing: 15) {
            RecapPlaceholderThumbnail(kind: card.collection)
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                RecapCategoryPill(title: RecapPresentation.collectionDisplay(for: card.collection).title)

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.title)
                        .font(.system(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                        .lineLimit(1)
                    Text(card.summary)
                        .font(.system(size: 12, weight: .medium))
                        .tracking(-0.24)
                        .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            RecapIconView(
                icon: .star,
                size: 24,
                color: isStarred ? RecapTheme.ColorToken.primary : RecapTheme.ColorToken.gray200
            )
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
}

private struct RecapCategoryPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .tracking(-0.20)
            .foregroundStyle(RecapTheme.ColorToken.primaryLight)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(RecapTheme.ColorToken.primarySoft)
            .clipShape(Capsule())
    }
}

private struct RecapPlaceholderThumbnail: View {
    let kind: CollectionKind

    var body: some View {
        let collection = RecapPresentation.collectionDisplay(for: kind)

        RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
            .fill(RecapTheme.ColorToken.thumbnail)
            .overlay(
                RoundedRectangle(cornerRadius: RecapTheme.Radius.small, style: .continuous)
                    .fill(collection.dotColor.opacity(0.08))
            )
            .overlay(
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                    .foregroundStyle(collection.dotColor.opacity(0.55))
            )
    }
}

#Preview("Figma cards") {
    ZStack {
        RecapTheme.ColorToken.background.ignoresSafeArea()
        ScrollView {
            VStack(alignment: .leading, spacing: RecapTheme.Spacing.large) {
                RecentRecapCard(card: SampleData.cards[0])
                ArchiveListCard(card: SampleData.cards[1])
                OrganizeRecapCard(card: SampleData.cards[2], isStarred: true)
            }
            .padding()
        }
    }
}
