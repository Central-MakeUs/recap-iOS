import Foundation

/// 값 타입 카드에 대한 검색·복사 헬퍼.
///
/// 화면 모델들이 사본 상태를 들고 있는 동안만 필요하다. 카드가 `CardStore`의
/// 공유 인스턴스로 옮겨가면(#111 5단계) 함께 사라진다.
enum RecapCardCollection {
    static func search(_ cards: [InformationCard], query: String) -> [InformationCard] {
        guard !query.isEmpty else { return [] }
        return cards.filter { card in
            card.title.localizedCaseInsensitiveContains(query)
                || card.summary.localizedCaseInsensitiveContains(query)
                || card.category.localizedCaseInsensitiveContains(query)
                || card.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

/// 순수 값 복사라 격리가 필요 없다. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
/// 아래에서는 extension 멤버가 암묵적으로 MainActor가 되므로 명시한다.
nonisolated extension InformationCard {
    func with(editDraft draft: CardEditDraft) -> InformationCard {
        InformationCard(
            captureID: captureID,
            title: draft.title,
            summary: draft.summary,
            collection: draft.collection,
            organizedAt: organizedAt,
            location: location,
            businessHours: businessHours,
            category: draft.collection.displayTitle,
            confirmationLabel: confirmationLabel,
            memo: draft.body,
            tags: tags,
            originalImageAssetName: originalImageAssetName,
            thumbnailAssetName: thumbnailAssetName,
            originalImageURL: originalImageURL,
            thumbnailURL: thumbnailURL,
            isFavorite: isFavorite
        )
    }
}
