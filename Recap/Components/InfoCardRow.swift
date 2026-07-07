import SwiftUI

struct InfoCardRow: View {
    let card: InformationCard
    var showsDate = true

    var body: some View {
        let collection = RecapPresentation.collectionDisplay(for: card.collection)

        HStack(spacing: RecapTheme.Spacing.medium) {
            PlaceholderThumbnail(kind: card.collection)

            VStack(alignment: .leading, spacing: RecapTheme.Spacing.xSmall) {
                Text(card.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RecapTheme.ColorToken.textPrimary)
                    .lineLimit(1)

                Text(card.summary)
                    .font(.caption)
                    .foregroundStyle(RecapTheme.ColorToken.textSecondary)
                    .lineLimit(1)

                HStack(spacing: RecapTheme.Spacing.xSmall) {
                    Circle()
                        .fill(collection.dotColor)
                        .frame(width: 5, height: 5)
                    Text(collection.title)
                    if showsDate {
                        Text("·")
                        Text(card.dateText)
                    }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RecapTheme.ColorToken.textSecondary)
            }

            Spacer(minLength: RecapTheme.Spacing.small)
        }
        .padding(RecapTheme.Spacing.medium)
        .recapCard(radius: RecapTheme.Radius.medium)
    }
}

struct PlaceholderThumbnail: View {
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
            .frame(width: 54, height: 54)
    }
}

#Preview {
    VStack {
        InfoCardRow(card: SampleData.cards[0])
        InfoCardRow(card: SampleData.cards[1])
    }
    .padding()
    .background(RecapTheme.ColorToken.background)
}
