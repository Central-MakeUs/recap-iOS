enum PreviewActions {
    nonisolated static func noop() {}

    nonisolated static func handleCardSelection(_ id: InformationCard.ID) {}

    nonisolated static func handleHome(_ action: HomeAction) {}

    nonisolated static func handleOrganize(_ action: OrganizeAction) {}

    nonisolated static func handleArchive(_ action: ArchiveAction) {}

    nonisolated static func handleSearch(_ action: SearchAction) {}

    nonisolated static func handleCardDetail(_ action: CardDetailAction) {}

}
