#if DEBUG
enum PreviewStores {
    static func recapCardStore() -> RecapCardStore {
        RecapCardStore(cards: SampleData.cards)
    }
}
#endif
