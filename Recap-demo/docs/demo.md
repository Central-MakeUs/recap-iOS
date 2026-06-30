# RE-CAP iOS OCR 기술 검증 데모 앱

## 1. 문서 목적

이 문서는 RE-CAP의 iOS 온디바이스 OCR 및 룰베이스 분류 가능성을 검증하기 위한 데모 앱 구현 범위를 정의한다.

이 앱은 실제 서비스 앱이 아니라 다음 항목을 측정하고 판단하기 위한 기술 검증용 앱이다.

1. 스크린샷만 선택할 수 있는가
2. 최대 20장의 스크린샷을 OCR 처리하는 데 얼마나 걸리는가
3. iOS 26에서 OCR을 백그라운드로 계속 처리할 수 있는가
4. 포그라운드와 백그라운드의 처리 시간 차이는 어느 정도인가
5. Vision OCR 결과가 서비스에 활용할 수 있을 정도인지
6. OCR 텍스트를 룰베이스만으로 네 가지 저장 목적에 분류할 수 있는지

---

## 2. 기술 전제

- 플랫폼: iOS
- 최소 지원 버전: iOS 26
- UI: SwiftUI
- 이미지 선택: PhotosPicker
- 이미지 필터: 스크린샷 전용
- OCR: Apple Vision
- 백그라운드 처리: BGContinuedProcessingTask
- 로컬 저장: SwiftData 또는 파일 기반 JSON
- 서버 연동: 제외
- Gemini 및 외부 AI 연동: 제외
- 최대 선택 개수: 20장

---

## 3. 검증 범위

### 3.1 포함 범위

- 스크린샷 전용 다중 선택
- 최대 20장 선택 제한
- Vision을 이용한 온디바이스 OCR
- 이미지별 OCR 시간 측정
- 전체 배치 OCR 시간 측정
- 포그라운드 OCR
- iOS 26 백그라운드 OCR
- 포그라운드와 백그라운드 처리 시간 비교
- OCR 결과 직접 확인 및 수동 평가
- OCR 텍스트 기반 룰베이스 분류
- 예측 카테고리와 실제 카테고리 비교
- 실험 결과 로컬 저장
- JSON 또는 CSV 결과 내보내기

### 3.2 제외 범위

- 로그인
- 서버 API
- 이미지 서버 업로드
- 서버 OCR
- Gemini 호출
- 자체 AI 모델
- 실제 컬렉션 기능
- 검색 기능
- Share Extension
- 푸시 알림
- 정식 디자인 시스템
- Android 구현

---

## 4. 검증 대상 카테고리

스크린샷의 내용 자체가 아니라 사용자가 저장한 목적을 기준으로 네 가지 중 하나로 분류한다.

### 4.1 비교할 후보

상품, 맛집, 숙소처럼 여러 선택지를 비교하거나 고르기 위해 저장한 캡처다.

예시 신호:

- 가격
- 할인
- 후기
- 평점
- 옵션
- 메뉴
- 객실
- 위치
- 영업시간
- 찜
- 장바구니
- 무료 취소
- 배송비

### 4.2 챙겨야 할 정보

예약, 마감, 신청처럼 이후 특정 시점에 다시 확인하거나 행동해야 하는 캡처다.

예시 신호:

- 예약 완료
- 예약번호
- 신청 완료
- 접수 완료
- 마감
- 기한
- 체크인
- 체크아웃
- 탑승
- 예매
- 방문 예정
- 제출
- 일정
- 미래 날짜

### 4.3 참고할 자료

글, 강의, 문서, 레퍼런스처럼 나중에 학습하거나 다시 활용하기 위해 저장한 캡처다.

예시 신호:

- 강의
- 튜토리얼
- 목차
- 개념
- 예제
- 코드
- 문서
- 논문
- 레퍼런스
- 가이드
- 사용법
- 아티클

### 4.4 남겨둘 기록

결제, 영수증, 거래 내역, 오류처럼 확인이나 증빙을 위해 남긴 캡처다.

예시 신호:

- 결제 완료
- 영수증
- 승인번호
- 주문번호
- 거래 내역
- 환불
- 오류
- 실패
- Exception
- Error
- 문의번호
- 접수번호

---

## 5. 핵심 사용자 흐름

```text
앱 실행
→ 실험 설정
→ 스크린샷 최대 20장 선택
→ OCR 시작
→ 포그라운드 또는 백그라운드 처리
→ 이미지별 OCR 결과 저장
→ 룰베이스 분류
→ 결과 목록 표시
→ 이미지별 OCR 품질 및 실제 분류 수동 평가
→ 실험 결과 저장 및 내보내기
```

---

## 6. 화면 구성

## 6.1 실험 설정 화면

실험 조건을 설정한다.

필수 항목:

- OCR 실행 모드
  - 포그라운드
  - 백그라운드
- OCR 인식 수준
  - fast
  - accurate
- 인식 언어
  - 자동 감지
  - 한국어 및 영어 지정
- 언어 교정
  - 사용
  - 미사용
- 선택 이미지 수
  - 최대 20장
- 실험 메모
  - 선택 사항

필수 버튼:

- 스크린샷 선택
- 이전 실험 결과 보기

---

## 6.2 스크린샷 선택 화면

PhotosPicker를 이용한다.

요구사항:

- 스크린샷만 표시
- 최대 20장 선택
- 현재 선택 개수 표시
- 선택한 이미지 목록 표시
- 선택 취소 가능
- OCR 시작 버튼 제공

표시 정보:

- 선택 개수
- 각 이미지의 썸네일
- 가능한 경우 이미지 크기
- 가능한 경우 파일 크기

테스트 장수:

- 1장
- 5장
- 10장
- 15장
- 20장

---

## 6.3 OCR 처리 화면

OCR 진행 상황을 실시간으로 표시한다.

표시 항목:

- 전체 이미지 수
- 완료 이미지 수
- 실패 이미지 수
- 현재 처리 중인 이미지 번호
- 전체 진행률
- 전체 경과 시간
- 현재 이미지 OCR 시간
- 현재 앱 상태
  - active
  - inactive
  - background
- 백그라운드 작업 상태
- 취소 버튼

예시:

```text
OCR 처리 중

진행률: 8 / 20
경과 시간: 4.8초
현재 이미지 OCR: 0.42초
앱 상태: Background
```

---

## 6.4 결과 목록 화면

이미지별 결과를 목록으로 표시한다.

각 항목:

- 썸네일
- OCR 성공 여부
- OCR 처리 시간
- 추출된 텍스트 일부
- 룰베이스 예측 카테고리
- 수동 평가 여부

상단 요약:

- 전체 이미지 수
- OCR 성공 수
- OCR 실패 수
- 전체 처리 시간
- 이미지당 평균 처리 시간
- 최장 처리 시간
- 예측 정답 수
- 예측 오답 수
- 미평가 수

---

## 6.5 이미지 상세 평가 화면

OCR 결과와 분류 결과를 사람이 직접 확인한다.

표시 항목:

- 원본 스크린샷
- 전체 OCR 텍스트
- OCR confidence
- OCR 처리 시간
- 추출된 텍스트 블록 수
- 예측 카테고리
- 카테고리별 점수
- 매칭된 규칙
- 실제 정답 카테고리

OCR 품질 수동 평가:

- 좋음
- 일부 오류
- 사용 불가

실제 카테고리 선택:

- 비교할 후보
- 챙겨야 할 정보
- 참고할 자료
- 남겨둘 기록
- 분류하기 어려움

선택적 메모:

- OCR 오류
- 룰 부족
- 카테고리 정의가 애매함
- 기타

---

## 6.6 실험 기록 화면

이전 실험 결과를 표시한다.

각 실험 항목:

- 실험 시각
- 이미지 수
- 실행 모드
- OCR 설정
- 전체 처리 시간
- 이미지당 평균 시간
- OCR 성공률
- 룰베이스 정확도

기능:

- 실험 상세 보기
- 실험 삭제
- JSON 내보내기
- CSV 내보내기

---

## 7. OCR 처리 요구사항

## 7.1 OCR 파이프라인

```text
PhotosPickerItem
→ 이미지 데이터 로드
→ CGImage 생성
→ Vision OCR 실행
→ 텍스트 블록 결합
→ OCR 결과 저장
→ 룰베이스 분류
```

## 7.2 측정 구간

이미지별로 최소 다음 값을 기록한다.

- 이미지 로딩 시간
- Vision OCR 실행 시간
- OCR 결과 변환 시간
- 이미지별 전체 처리 시간

배치 단위로 다음 값을 기록한다.

- 첫 결과가 나온 시간
- 전체 처리 시간
- 이미지당 평균 처리 시간
- 이미지당 최장 처리 시간
- OCR 성공 수
- OCR 실패 수

## 7.3 처리 방식

초기 구현은 순차 처리로 한다.

```text
이미지 1 로드
→ OCR
→ 결과 저장
→ 메모리 해제
→ 이미지 2 처리
```

모든 이미지를 한 번에 메모리에 올리지 않는다.

병렬 처리는 이번 데모의 필수 범위가 아니다.

---

## 8. 백그라운드 처리 요구사항

## 8.1 대상 API

iOS 26의 BGContinuedProcessingTask를 사용한다.

## 8.2 기본 흐름

```text
사용자가 OCR 시작
→ 백그라운드 지속 작업 등록
→ OCR 실행
→ 사용자가 홈 화면으로 이동
→ OCR 계속 진행
→ 각 이미지 완료 시 로컬 저장
→ 작업 완료
```

## 8.3 검증 시나리오

다음 시나리오를 테스트한다.

### 시나리오 A

```text
10장 OCR 시작
→ 즉시 홈 화면 이동
→ 완료까지 대기
→ 앱 복귀
```

### 시나리오 B

```text
20장 OCR 시작
→ 3장 처리 후 홈 화면 이동
→ 완료까지 대기
→ 앱 복귀
```

### 시나리오 C

```text
20장 OCR 시작
→ 화면 잠금
→ 완료 여부 확인
```

### 시나리오 D

```text
20장 OCR 시작
→ 다른 앱 사용
→ OCR 완료 여부 확인
```

### 시나리오 E

```text
OCR 진행 중 백그라운드 작업 취소
→ 앱 복귀
→ 중단 상태 확인
```

## 8.4 측정 항목

- 백그라운드 진입 시각
- 백그라운드 진입 전 완료 이미지 수
- 백그라운드에서 완료한 이미지 수
- 전체 완료 시각
- 백그라운드 전체 처리 시간
- 포그라운드 대비 시간 차이
- 시스템 중단 여부
- 사용자 취소 여부
- 앱 복귀 시 결과 동기화 여부

---

## 9. OCR 품질 확인

OCR 정확도는 자동 점수화하지 않고 사람이 직접 확인한다.

각 이미지에서 다음을 확인한다.

- 한글 문장이 자연스럽게 추출되는가
- 영어와 숫자가 정상적으로 인식되는가
- 금액이 정확하게 추출되는가
- 날짜와 시간이 정확하게 추출되는가
- 예약번호, 주문번호, 승인번호가 누락되지 않는가
- 오류 코드가 정확하게 추출되는가
- 줄 순서가 심하게 뒤섞이지 않는가
- 긴 스크린샷에서도 주요 텍스트가 누락되지 않는가

수동 평가값:

```swift
enum OCRQuality: String, Codable {
    case good
    case partial
    case unusable
}
```

---

## 10. 룰베이스 분류

## 10.1 분류 방식

가중치 기반 점수 방식을 사용한다.

```text
OCR 텍스트
→ 정규화
→ 키워드 및 정규식 탐지
→ 카테고리별 점수 계산
→ 최고 점수 카테고리 선택
```

## 10.2 텍스트 정규화

다음 작업을 수행한다.

- 소문자 변환
- 불필요한 공백 제거
- 줄바꿈 정리
- 통화 기호 정리
- 숫자 형식 정리
- 한글 및 영문 키워드 비교 가능하도록 변환

## 10.3 구조적 신호

다음 신호를 추출한다.

```swift
struct ExtractedSignals: Codable {
    var hasAmount: Bool
    var hasDate: Bool
    var hasFutureDate: Bool
    var hasTime: Bool
    var hasReservationNumber: Bool
    var hasOrderNumber: Bool
    var hasApprovalNumber: Bool
    var hasErrorCode: Bool
    var hasURL: Bool
}
```

주의:

Vision은 위 신호를 직접 제공하지 않는다.

Vision은 OCR 텍스트를 제공하고, 신호는 정규식과 키워드 규칙으로 직접 추출한다.

## 10.4 초기 점수 규칙 예시

아래 점수는 확정값이 아니라 데모 실험용 초기값이다.

### 비교할 후보

| 규칙 | 점수 |
|---|---:|
| 후기 | +3 |
| 평점 | +3 |
| 옵션 | +2 |
| 객실 | +2 |
| 메뉴 | +2 |
| 영업시간 | +2 |
| 위치 | +1 |
| 가격 | +1 |
| 할인 | +1 |
| 무료 취소 | +1 |
| 찜 | +2 |
| 장바구니 | +2 |

### 챙겨야 할 정보

| 규칙 | 점수 |
|---|---:|
| 예약 완료 | +5 |
| 예약번호 | +5 |
| 신청 완료 | +4 |
| 접수 완료 | +4 |
| 마감 | +4 |
| 기한 | +3 |
| 체크인 | +3 |
| 체크아웃 | +3 |
| 예매번호 | +4 |
| 탑승 | +3 |
| 미래 날짜 | +2 |

### 참고할 자료

| 규칙 | 점수 |
|---|---:|
| 강의 | +4 |
| 튜토리얼 | +4 |
| 목차 | +3 |
| 예제 | +3 |
| 코드 | +2 |
| 문서 | +2 |
| 논문 | +4 |
| 레퍼런스 | +3 |
| 가이드 | +3 |
| 사용법 | +3 |
| 아티클 | +2 |

### 남겨둘 기록

| 규칙 | 점수 |
|---|---:|
| 영수증 | +5 |
| 결제 완료 | +5 |
| 승인번호 | +4 |
| 주문번호 | +3 |
| 거래 내역 | +4 |
| 환불 완료 | +4 |
| 오류 코드 | +5 |
| Exception | +4 |
| Error | +3 |
| 실패 | +3 |
| 문의번호 | +3 |
| 접수번호 | +3 |

## 10.5 분류 결과

```swift
enum ScreenshotCategory: String, Codable, CaseIterable {
    case comparisonCandidate
    case actionRequired
    case reference
    case record
    case unclassified
}
```

분류 결과에는 다음 정보를 포함한다.

```swift
struct ClassificationResult: Codable {
    let predictedCategory: ScreenshotCategory
    let scores: [ScreenshotCategory: Int]
    let matchedRules: [MatchedRule]
    let isAmbiguous: Bool
}
```

## 10.6 분류 불가 기준

다음 경우에는 `unclassified`로 처리한다.

- 모든 카테고리 점수가 0점
- 최고 점수가 최소 기준보다 낮음
- 1위와 2위의 점수 차이가 너무 작음
- OCR 텍스트가 비어 있음
- OCR 텍스트가 지나치게 짧음

최소 점수와 점수 차이 기준은 데모에서 조정 가능하도록 한다.

예:

```text
최소 확정 점수: 3점
최소 점수 차이: 2점
```

---

## 11. 데이터 모델

## 11.1 OCR 실험

```swift
struct OCRExperiment: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    var finishedAt: Date?

    let executionMode: ExecutionMode
    let recognitionLevel: RecognitionLevel
    let imageCount: Int

    var status: ExperimentStatus
    var results: [OCRImageResult]

    var totalDuration: TimeInterval?
    var firstResultDuration: TimeInterval?
}
```

## 11.2 이미지별 결과

```swift
struct OCRImageResult: Identifiable, Codable {
    let id: UUID
    let order: Int

    var width: Int?
    var height: Int?
    var fileSize: Int64?

    var loadDuration: TimeInterval?
    var ocrDuration: TimeInterval?
    var totalDuration: TimeInterval?

    var recognizedText: String
    var averageConfidence: Float?
    var textBlockCount: Int

    var status: OCRImageStatus
    var errorMessage: String?

    var classificationResult: ClassificationResult?
    var actualCategory: ScreenshotCategory?
    var ocrQuality: OCRQuality?
    var evaluationMemo: String?
}
```

## 11.3 상태

```swift
enum OCRImageStatus: String, Codable {
    case pending
    case loading
    case recognizing
    case completed
    case failed
    case cancelled
}

enum ExperimentStatus: String, Codable {
    case ready
    case running
    case completed
    case cancelled
    case failed
}

enum ExecutionMode: String, Codable {
    case foreground
    case background
}
```

---

## 12. 프로젝트 구조 제안

```text
RECAPOCRDemo/
├── App/
│   └── RECAPOCRDemoApp.swift
│
├── Presentation/
│   ├── ExperimentSetupView.swift
│   ├── ScreenshotPickerView.swift
│   ├── OCRProcessingView.swift
│   ├── OCRResultListView.swift
│   ├── OCRResultDetailView.swift
│   └── ExperimentHistoryView.swift
│
├── Domain/
│   ├── OCRExperiment.swift
│   ├── OCRImageResult.swift
│   ├── ScreenshotCategory.swift
│   ├── ClassificationResult.swift
│   └── OCRQuality.swift
│
├── OCR/
│   ├── VisionOCRService.swift
│   ├── OCRCoordinator.swift
│   └── OCRMetricsCalculator.swift
│
├── Classification/
│   ├── RuleBasedClassifier.swift
│   ├── SignalExtractor.swift
│   ├── ClassificationRule.swift
│   └── DefaultRuleSet.swift
│
├── Background/
│   └── BackgroundOCRCoordinator.swift
│
├── Persistence/
│   ├── ExperimentRepository.swift
│   └── FileExperimentRepository.swift
│
├── Export/
│   ├── JSONExporter.swift
│   └── CSVExporter.swift
│
└── Shared/
    ├── AppLogger.swift
    ├── ContinuousClock+Measure.swift
    └── Extensions/
```

---

## 13. 구현 순서

## 13.1 1단계: 스크린샷 선택

- SwiftUI 프로젝트 생성
- 최소 지원 버전 iOS 26 설정
- PhotosPicker 구현
- 스크린샷 필터 적용
- 최대 20장 제한
- 선택 이미지 썸네일 표시

완료 조건:

- 스크린샷만 표시된다
- 20장 이상 선택할 수 없다
- 선택한 이미지를 앱에서 읽을 수 있다

## 13.2 2단계: Vision OCR

- Vision OCR 서비스 구현
- 이미지 한 장 OCR
- OCR 텍스트와 confidence 표시
- 이미지별 OCR 시간 측정

완료 조건:

- 한글, 영어, 숫자가 포함된 스크린샷에서 텍스트가 출력된다
- OCR 시간과 전체 처리 시간이 분리되어 기록된다

## 13.3 3단계: 최대 20장 순차 처리

- 선택 순서대로 OCR
- 이미지별 상태 관리
- 진행률 표시
- 전체 처리 시간 계산
- 실패한 이미지가 전체 작업을 중단하지 않도록 처리

완료 조건:

- 1, 5, 10, 15, 20장 실험이 가능하다
- 각 실험 결과가 저장된다

## 13.4 4단계: 결과 및 수동 평가

- 결과 목록 구현
- 이미지 상세 화면 구현
- OCR 품질 수동 평가
- 실제 카테고리 지정
- 평가 메모 저장

완료 조건:

- 각 OCR 결과를 원본과 비교할 수 있다
- 사용자가 실제 정답 카테고리를 지정할 수 있다

## 13.5 5단계: 룰베이스 분류

- 키워드 규칙 구현
- 정규식 기반 구조 신호 구현
- 카테고리별 점수 계산
- 분류 근거 표시
- `unclassified` 기준 구현

완료 조건:

- 각 이미지에 네 카테고리 또는 분류 불가 결과가 표시된다
- 카테고리별 점수와 매칭된 규칙을 확인할 수 있다

## 13.6 6단계: 백그라운드 처리

- BGContinuedProcessingTask 등록
- OCR 작업 연결
- 백그라운드 진행 상태 반영
- 취소 처리
- 앱 복귀 시 결과 동기화

완료 조건:

- 10장과 20장 OCR을 백그라운드에서 실행할 수 있다
- 포그라운드와 백그라운드 처리 시간을 비교할 수 있다

## 13.7 7단계: 결과 내보내기

- JSON 내보내기
- CSV 내보내기
- ShareLink 제공

완료 조건:

- 실험 결과를 외부에서 분석할 수 있는 파일로 내보낼 수 있다

---

## 14. 필수 테스트 시나리오

## 14.1 포그라운드 OCR

같은 이미지 묶음을 이용해 각각 최소 3회 실행한다.

- 1장
- 5장
- 10장
- 15장
- 20장

기록:

- 전체 처리 시간
- 이미지당 평균 시간
- 이미지별 최장 시간
- OCR 실패 수

## 14.2 백그라운드 OCR

같은 10장 및 20장 이미지 묶음을 이용한다.

- OCR 시작 직후 홈 화면 이동
- 일부 이미지 처리 후 홈 화면 이동
- 화면 잠금
- 다른 앱 사용
- 작업 취소

기록:

- 전체 처리 시간
- 백그라운드에서 처리된 이미지 수
- 시스템 중단 여부
- 앱 복귀 후 결과 일치 여부

## 14.3 OCR 품질 평가

다음 유형의 스크린샷을 포함한다.

- 상품
- 맛집
- 숙소
- 예약 완료
- 신청 및 마감
- 결제 내역
- 영수증
- 오류 화면
- 강의 및 글
- 코드 또는 개발 문서
- 한글 및 영문 혼합
- 긴 스크롤 스크린샷

## 14.4 룰베이스 분류

각 카테고리의 실제 정답 샘플을 준비한다.

권장 최소 수량:

- 비교할 후보: 10장
- 챙겨야 할 정보: 10장
- 참고할 자료: 10장
- 남겨둘 기록: 10장

총 40장 이상을 권장한다.

---

## 15. 결과 계산

## 15.1 OCR 성능

다음 값을 계산한다.

```text
평균 OCR 시간
= 전체 이미지 OCR 시간 합계 / 성공 이미지 수
```

```text
포그라운드 대비 백그라운드 증가율
= (백그라운드 시간 - 포그라운드 시간)
  / 포그라운드 시간
  × 100
```

## 15.2 룰베이스 분류

다음 값을 계산한다.

- 전체 평가 수
- 정답 수
- 오답 수
- 분류 불가 수
- 전체 정확도
- 카테고리별 정확도

```text
전체 정확도
= 정답 수 / 평가 완료 수
```

`unclassified`는 별도로 집계한다.

추가로 기록할 내용:

- OCR 오류 때문에 잘못 분류된 사례
- 규칙 부족 때문에 잘못 분류된 사례
- 카테고리 정의가 겹치는 사례
- 비교할 후보와 챙겨야 할 정보의 혼동
- 챙겨야 할 정보와 남겨둘 기록의 혼동

---

## 16. 최종 산출물

데모 앱 구현 후 다음 결과를 확보해야 한다.

### 16.1 OCR 처리 결과표

| 장수 | 포그라운드 시간 | 백그라운드 시간 | 장당 평균 | OCR 실패 |
|---:|---:|---:|---:|---:|
| 1 |  | - |  |  |
| 5 |  | - |  |  |
| 10 |  |  |  |  |
| 15 |  |  |  |  |
| 20 |  |  |  |  |

### 16.2 룰베이스 분류 결과표

| 카테고리 | 평가 수 | 정답 | 오답 | 분류 불가 | 정확도 |
|---|---:|---:|---:|---:|---:|
| 비교할 후보 |  |  |  |  |  |
| 챙겨야 할 정보 |  |  |  |  |  |
| 참고할 자료 |  |  |  |  |  |
| 남겨둘 기록 |  |  |  |  |  |

### 16.3 최종 판단

데모 결과를 통해 다음을 결정한다.

1. 최대 20장까지 온디바이스 OCR이 충분히 빠른가
2. 최대 20장까지 백그라운드에서 안정적으로 완료되는가
3. 포그라운드와 백그라운드의 처리 시간 차이가 허용 가능한가
4. Vision OCR 품질이 분류 입력으로 사용 가능한가
5. 룰베이스만으로 네 카테고리를 분류할 수 있는가
6. 룰베이스 분류 불가 비율은 어느 정도인가
7. 향후 Gemini 같은 AI fallback이 필요한가

---

## 17. Codex 구현 지침

- 한 번에 전체 기능을 구현하지 않는다.
- 각 단계가 동작하는지 확인한 뒤 다음 단계로 진행한다.
- View에 OCR 및 분류 로직을 직접 작성하지 않는다.
- OCR, 분류, 저장, 백그라운드 처리를 별도 타입으로 분리한다.
- 모든 비동기 작업은 취소 가능해야 한다.
- OCR 실패 한 건이 전체 배치를 실패시키지 않아야 한다.
- 이미지 전체를 한 번에 메모리에 올리지 않는다.
- 이미지별 결과를 완료 즉시 저장한다.
- 백그라운드 작업이 중단되어도 완료된 결과는 유지한다.
- 룰 점수와 매칭된 규칙을 화면에서 확인할 수 있게 한다.
- 규칙 점수는 하드코딩하더라도 한 파일에서 관리한다.
- 실험 결과를 재현할 수 있도록 설정값을 함께 저장한다.
- 데모 목적에 불필요한 추상화와 외부 라이브러리는 피한다.

---

## 18. 완료 정의

다음 조건을 모두 만족하면 데모 앱 구현을 완료한 것으로 본다.

- [ ] 스크린샷만 최대 20장 선택할 수 있다.
- [ ] 선택한 스크린샷을 Vision으로 OCR 처리할 수 있다.
- [ ] 이미지별 OCR 시간과 전체 시간을 확인할 수 있다.
- [ ] 1, 5, 10, 15, 20장 실험을 수행할 수 있다.
- [ ] iOS 26 백그라운드 지속 처리 기능을 검증할 수 있다.
- [ ] 포그라운드와 백그라운드 처리 시간을 비교할 수 있다.
- [ ] 원본 이미지와 OCR 텍스트를 함께 확인할 수 있다.
- [ ] OCR 품질을 사람이 직접 평가할 수 있다.
- [ ] 룰베이스로 네 카테고리를 예측할 수 있다.
- [ ] 예측 근거와 카테고리별 점수를 확인할 수 있다.
- [ ] 사용자가 실제 정답 카테고리를 지정할 수 있다.
- [ ] 룰베이스 정확도를 계산할 수 있다.
- [ ] 결과를 JSON 또는 CSV로 내보낼 수 있다.
