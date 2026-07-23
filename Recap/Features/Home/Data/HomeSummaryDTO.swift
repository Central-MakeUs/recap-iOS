import Foundation

nonisolated struct HomeSummaryDTO: Decodable, Sendable {
    let recentCaptures: [HomeCaptureSummaryDTO]
    let favorites: [HomeCaptureSummaryDTO]
    let topTypes: [HomeTopTypeDTO]
    let hasAnyCapture: Bool
}

nonisolated struct HomeCaptureSummaryDTO: Decodable, Sendable {
    let captureId: Int64
    let title: String
    let summary: String
    let typeCode: HomeCardTypeCode
    let thumbnailUrl: URL?
    let isFavorite: Bool
    let organizedAt: Date
}

nonisolated struct HomeTopTypeDTO: Decodable, Sendable {
    let typeCode: HomeCardTypeCode
    let count: Int
    let representativeThumbnailUrl: URL?
}

nonisolated enum HomeCardTypeCode: String, Decodable, Sendable {
    case job = "JOB"
    case shopping = "SHOPPING"
    case place = "PLACE"
    case schedule = "SCHEDULE"
    case knowledge = "KNOWLEDGE"
    case content = "CONTENT"
    case benefit = "BENEFIT"
    case record = "RECORD"
    case etc = "ETC"

    var collectionKind: CollectionKind {
        switch self {
        case .job:
            .career
        case .shopping:
            .shopping
        case .place:
            .place
        case .schedule:
            .schedule
        case .knowledge:
            .knowledge
        case .content:
            .content
        case .benefit:
            .benefits
        case .record:
            .capture
        case .etc:
            .other
        }
    }

    var displayTitle: String {
        switch self {
        case .job:
            "채용 · 취업"
        case .shopping:
            "쇼핑 · 상품"
        case .place:
            "장소 · 맛집"
        case .schedule:
            "일정 · 예약"
        case .knowledge:
            "정보 · 지식"
        case .content:
            "책 · 콘텐츠"
        case .benefit:
            "혜택 · 이벤트"
        case .record:
            "기록 · 캡처"
        case .etc:
            "기타"
        }
    }
}
