import Foundation

struct ClassificationRule: Hashable {
    let category: ScreenshotCategory
    let pattern: String
    let score: Int
}

struct SignalExtractor {
    func extract(from text: String, compactText: String, now: Date = Date()) -> ExtractedSignals {
        var signals = ExtractedSignals()
        signals.hasAmount = matches(text, #"(₩|￦|원|usd|\$)\s?[0-9,]+|[0-9,]+\s?(원|달러|krw)"#)
        signals.hasDate = matches(text, #"\d{4}[./-]\d{1,2}[./-]\d{1,2}|\d{1,2}[./-]\d{1,2}|\d{1,2}\s?월\s?\d{1,2}\s?일"#)
        signals.hasTime = matches(text, #"\d{1,2}:\d{2}|오전|오후|am|pm"#)
        signals.hasReservationNumber = compactText.contains("예약번호") || compactText.contains("예매번호") || matches(text, #"reservation\s?(no|number)"#)
        signals.hasOrderNumber = compactText.contains("주문번호") || compactText.contains("주문내역") || matches(text, #"order\s?(no|number|id)"#)
        signals.hasApprovalNumber = compactText.contains("승인번호") || compactText.contains("승인내역") || text.contains("approval")
        signals.hasErrorCode = text.contains("error") || text.contains("exception") || compactText.contains("오류코드") || matches(text, #"[a-z]{2,}-?\d{3,}"#)
        signals.hasURL = matches(text, #"https?://|www\.|\.com|\.kr"#)
        signals.hasFutureDate = signals.hasDate && containsLikelyFutureHint(compactText)
        return signals
    }

    private func containsLikelyFutureHint(_ text: String) -> Bool {
        ["예정", "마감", "기한", "체크인", "체크아웃", "탑승", "방문", "예약", "일정", "알림"].contains { text.contains($0) }
    }

    private func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}

struct RuleBasedClassifier {
    /// 데모에서는 룰베이스 confidence가 없으므로 이 값은 "확신 높음/낮음" 표시 기준일 뿐,
    /// 최선 예측을 unclassified로 지우는 기준으로 사용하지 않는다.
    var strongScore: Int = 3
    var strongGap: Int = 2
    var signalExtractor = SignalExtractor()

    private let rules: [ClassificationRule] = [
        .init(category: .comparisonCandidate, pattern: "후기", score: 3),
        .init(category: .comparisonCandidate, pattern: "리뷰", score: 3),
        .init(category: .comparisonCandidate, pattern: "평점", score: 3),
        .init(category: .comparisonCandidate, pattern: "별점", score: 3),
        .init(category: .comparisonCandidate, pattern: "옵션", score: 2),
        .init(category: .comparisonCandidate, pattern: "객실", score: 2),
        .init(category: .comparisonCandidate, pattern: "숙소", score: 2),
        .init(category: .comparisonCandidate, pattern: "메뉴", score: 2),
        .init(category: .comparisonCandidate, pattern: "맛집", score: 2),
        .init(category: .comparisonCandidate, pattern: "영업시간", score: 2),
        .init(category: .comparisonCandidate, pattern: "위치", score: 1),
        .init(category: .comparisonCandidate, pattern: "가격", score: 2),
        .init(category: .comparisonCandidate, pattern: "할인", score: 2),
        .init(category: .comparisonCandidate, pattern: "쿠폰", score: 1),
        .init(category: .comparisonCandidate, pattern: "무료취소", score: 2),
        .init(category: .comparisonCandidate, pattern: "무료 취소", score: 2),
        .init(category: .comparisonCandidate, pattern: "찜", score: 2),
        .init(category: .comparisonCandidate, pattern: "장바구니", score: 2),
        .init(category: .comparisonCandidate, pattern: "배송비", score: 1),
        .init(category: .comparisonCandidate, pattern: "review", score: 2),
        .init(category: .comparisonCandidate, pattern: "rating", score: 2),
        .init(category: .comparisonCandidate, pattern: "cart", score: 2),

        .init(category: .actionRequired, pattern: "예약완료", score: 5),
        .init(category: .actionRequired, pattern: "예약 완료", score: 5),
        .init(category: .actionRequired, pattern: "예약번호", score: 5),
        .init(category: .actionRequired, pattern: "신청완료", score: 4),
        .init(category: .actionRequired, pattern: "신청 완료", score: 4),
        .init(category: .actionRequired, pattern: "접수완료", score: 4),
        .init(category: .actionRequired, pattern: "접수 완료", score: 4),
        .init(category: .actionRequired, pattern: "마감", score: 4),
        .init(category: .actionRequired, pattern: "기한", score: 3),
        .init(category: .actionRequired, pattern: "체크인", score: 3),
        .init(category: .actionRequired, pattern: "체크아웃", score: 3),
        .init(category: .actionRequired, pattern: "예매번호", score: 4),
        .init(category: .actionRequired, pattern: "탑승", score: 3),
        .init(category: .actionRequired, pattern: "방문예정", score: 3),
        .init(category: .actionRequired, pattern: "방문 예정", score: 3),
        .init(category: .actionRequired, pattern: "제출", score: 2),
        .init(category: .actionRequired, pattern: "일정", score: 2),
        .init(category: .actionRequired, pattern: "알림", score: 1),
        .init(category: .actionRequired, pattern: "deadline", score: 3),
        .init(category: .actionRequired, pattern: "reservation", score: 3),
        .init(category: .actionRequired, pattern: "ticket", score: 2),

        .init(category: .reference, pattern: "강의", score: 4),
        .init(category: .reference, pattern: "튜토리얼", score: 4),
        .init(category: .reference, pattern: "목차", score: 3),
        .init(category: .reference, pattern: "개념", score: 2),
        .init(category: .reference, pattern: "예제", score: 3),
        .init(category: .reference, pattern: "코드", score: 2),
        .init(category: .reference, pattern: "문서", score: 2),
        .init(category: .reference, pattern: "논문", score: 4),
        .init(category: .reference, pattern: "레퍼런스", score: 3),
        .init(category: .reference, pattern: "가이드", score: 3),
        .init(category: .reference, pattern: "사용법", score: 3),
        .init(category: .reference, pattern: "아티클", score: 2),
        .init(category: .reference, pattern: "블로그", score: 2),
        .init(category: .reference, pattern: "뉴스", score: 1),
        .init(category: .reference, pattern: "insight", score: 2),
        .init(category: .reference, pattern: "tutorial", score: 4),
        .init(category: .reference, pattern: "documentation", score: 3),
        .init(category: .reference, pattern: "guide", score: 2),

        .init(category: .record, pattern: "영수증", score: 5),
        .init(category: .record, pattern: "결제완료", score: 5),
        .init(category: .record, pattern: "결제 완료", score: 5),
        .init(category: .record, pattern: "승인번호", score: 4),
        .init(category: .record, pattern: "주문번호", score: 3),
        .init(category: .record, pattern: "주문내역", score: 3),
        .init(category: .record, pattern: "거래내역", score: 4),
        .init(category: .record, pattern: "거래 내역", score: 4),
        .init(category: .record, pattern: "환불완료", score: 4),
        .init(category: .record, pattern: "환불 완료", score: 4),
        .init(category: .record, pattern: "오류코드", score: 5),
        .init(category: .record, pattern: "오류 코드", score: 5),
        .init(category: .record, pattern: "exception", score: 4),
        .init(category: .record, pattern: "error", score: 3),
        .init(category: .record, pattern: "실패", score: 3),
        .init(category: .record, pattern: "문의번호", score: 3),
        .init(category: .record, pattern: "접수번호", score: 3),
        .init(category: .record, pattern: "receipt", score: 5),
        .init(category: .record, pattern: "invoice", score: 4),
        .init(category: .record, pattern: "payment", score: 4)
    ]

    func classify(_ rawText: String) -> ClassificationResult {
        let normalized = normalize(rawText)
        let compactText = compact(normalized)
        let signals = signalExtractor.extract(from: normalized, compactText: compactText)
        var scores = Dictionary(uniqueKeysWithValues: ScreenshotCategory.allCases.map { ($0, 0) })
        var matched: [MatchedRule] = []

        guard normalized.count >= 4 else {
            return ClassificationResult(predictedCategory: .unclassified, scores: scores, matchedRules: [], extractedSignals: signals, isAmbiguous: true, confidence: .none, winningScore: 0, scoreGap: 0)
        }

        for rule in rules {
            let rulePattern = normalize(rule.pattern)
            let compactPattern = compact(rulePattern)
            if normalized.contains(rulePattern) || compactText.contains(compactPattern) {
                scores[rule.category, default: 0] += rule.score
                matched.append(MatchedRule(category: rule.category, pattern: rule.pattern, score: rule.score))
            }
        }

        applySignalScores(signals, scores: &scores, matched: &matched)

        let ranked = scores
            .filter { $0.key != .unclassified }
            .sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key.rawValue < rhs.key.rawValue : lhs.value > rhs.value }
        let best = ranked.first ?? (.unclassified, 0)
        let second = ranked.dropFirst().first?.value ?? 0
        let gap = max(0, best.value - second)

        guard best.value > 0 else {
            return ClassificationResult(predictedCategory: .unclassified, scores: scores, matchedRules: matched, extractedSignals: signals, isAmbiguous: true, confidence: .none, winningScore: 0, scoreGap: 0)
        }

        let strong = best.value >= strongScore && gap >= strongGap
        return ClassificationResult(predictedCategory: best.key, scores: scores, matchedRules: matched, extractedSignals: signals, isAmbiguous: !strong, confidence: strong ? .strong : .weak, winningScore: best.value, scoreGap: gap)
    }

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "₩", with: "원")
            .replacingOccurrences(of: "￦", with: "원")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func compact(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
    }

    private func applySignalScores(_ signals: ExtractedSignals, scores: inout [ScreenshotCategory: Int], matched: inout [MatchedRule]) {
        func add(_ category: ScreenshotCategory, _ pattern: String, _ score: Int) {
            scores[category, default: 0] += score
            matched.append(MatchedRule(category: category, pattern: pattern, score: score))
        }
        if signals.hasAmount { add(.comparisonCandidate, "금액", 2) }
        if signals.hasDate { add(.actionRequired, "날짜", 1) }
        if signals.hasFutureDate { add(.actionRequired, "미래 날짜", 3) }
        if signals.hasTime { add(.actionRequired, "시간", 1) }
        if signals.hasReservationNumber { add(.actionRequired, "예약/예매 번호", 5) }
        if signals.hasOrderNumber { add(.record, "주문번호", 4) }
        if signals.hasApprovalNumber { add(.record, "승인번호", 4) }
        if signals.hasErrorCode { add(.record, "오류 코드", 4) }
        if signals.hasURL { add(.reference, "URL", 2) }
    }
}
