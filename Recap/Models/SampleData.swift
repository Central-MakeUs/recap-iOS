import Foundation

enum SampleData {
    nonisolated static let cards: [InformationCard] = [
        InformationCard(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "성수동 브런치 맛집",
            summary: "서울숲 근처 · 10:00 - 20:00",
            collection: .comparison,
            dateText: "오늘",
            location: "서울숲 근처",
            businessHours: "10:00 - 20:00",
            category: "브런치 맛집",
            confirmationLabel: "주소 상세",
            memo: "주말 후보로 다시 보기",
            tags: ["성수동", "브런치", "맛집"]
        ),
        InformationCard(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "나이키 운동화 후보",
            summary: "에어맥스 129,000원 · 사이즈 240",
            collection: .comparison,
            dateText: "어제",
            location: "온라인 스토어",
            businessHours: "가격 129,000원",
            category: "운동화 후보",
            confirmationLabel: nil,
            memo: "비교 리스트에 남겨두기",
            tags: ["운동화", "가격비교", "사이즈240"]
        ),
        InformationCard(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "6월 공고 지원 안내",
            summary: "마감 6/30 · 지원 자격 요약",
            collection: .revisit,
            dateText: "오늘",
            location: "모바일 공고",
            businessHours: "마감 6월 30일",
            category: "지원 안내",
            confirmationLabel: "일정 확인",
            memo: "지원 조건 다시 확인",
            tags: ["공고", "마감", "지원"]
        ),
        InformationCard(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "제주 숙소 후보",
            summary: "1박 12만 원대 · 체크인 15:00",
            collection: .comparison,
            dateText: "6월 12일",
            location: "제주 서귀포",
            businessHours: "체크인 15:00",
            category: "숙소",
            confirmationLabel: nil,
            memo: "여행 후보로 비교",
            tags: ["제주", "숙소", "여행"]
        ),
        InformationCard(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            title: "결제 내역 캡처",
            summary: "주문번호 1842 · 총 42,000원",
            collection: .archive,
            dateText: "6월 10일",
            location: "온라인 주문",
            businessHours: "결제 완료",
            category: "결제 내역",
            confirmationLabel: nil,
            memo: "환불이나 문의 때 다시 확인",
            tags: ["결제", "주문", "기록"]
        ),
        InformationCard(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            title: "2026 모바일 UI 트렌드",
            summary: "온디바이스 AI · 카드형 요약",
            collection: .reference,
            dateText: "6월 9일",
            location: "레퍼런스 문서",
            businessHours: "읽기 자료",
            category: "디자인 참고",
            confirmationLabel: nil,
            memo: "홈 카드 레이아웃 참고",
            tags: ["디자인", "모바일", "레퍼런스"]
        )
    ]

    nonisolated static let recentCards: [InformationCard] = Array(cards.prefix(3))

    nonisolated static let collectionSummaries: [CollectionSummary] = [
        CollectionSummary(kind: .revisit, count: 12, previewTitle: "6월 공고 지원 안내"),
        CollectionSummary(kind: .comparison, count: 8, previewTitle: "성수동 브런치 맛집"),
        CollectionSummary(kind: .archive, count: 5, previewTitle: "결제 내역 캡처"),
        CollectionSummary(kind: .reference, count: 15, previewTitle: "2026 모바일 UI 트렌드")
    ]

    nonisolated static func cards(in kind: CollectionKind) -> [InformationCard] {
        cards.filter { $0.collection == kind }
    }

    nonisolated static func card(id: InformationCard.ID) -> InformationCard? {
        cards.first { $0.id == id }
    }

    nonisolated static func search(_ query: String) -> [InformationCard] {
        guard !query.isEmpty else { return Array(cards.prefix(2)) }
        return cards.filter { card in
            card.title.localizedCaseInsensitiveContains(query)
                || card.summary.localizedCaseInsensitiveContains(query)
                || card.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}
