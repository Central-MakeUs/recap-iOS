#if DEBUG
enum PreviewStores {
    static func cardStore() -> CardStore {
        let store = CardStore(captureMutator: PreviewCaptureService())
        store.upsert(SampleData.cards)
        return store
    }
}
#endif
