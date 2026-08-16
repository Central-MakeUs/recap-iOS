#if DEBUG
enum PreviewStores {
    /// `CardStore`가 MainActor라 이 헬퍼도 따라간다. 프리뷰 본문은 이미 MainActor다.
    @MainActor
    static func cardStore() -> CardStore {
        let store = CardStore(captureMutator: PreviewCaptureService())
        store.upsert(SampleData.cards)
        store.upsert(SampleData.recentCards)
        return store
    }
}
#endif
