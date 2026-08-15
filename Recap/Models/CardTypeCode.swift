import Foundation

nonisolated enum CardTypeCode: String, Codable, Sendable {
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

    init?(collectionKind: CollectionKind) {
        switch collectionKind {
        case .career:
            self = .job
        case .shopping:
            self = .shopping
        case .place:
            self = .place
        case .schedule:
            self = .schedule
        case .knowledge:
            self = .knowledge
        case .content:
            self = .content
        case .benefits:
            self = .benefit
        case .capture:
            self = .record
        case .other:
            self = .etc
        }
    }
}
