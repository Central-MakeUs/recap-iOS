import Foundation
import Observation

/// 화면들이 공유하는 카드 엔티티.
///
/// `captureID`(서버 정체성)당 인스턴스 하나를 `CardStore`가 보증한다. 참조를
/// 공유하므로 한 화면에서 바꾼 값이 다른 화면에 즉시 반영되고, 화면마다 사본을
/// 들고 재조회로 동기화할 필요가 없다.
///
/// 값 타입 `CardSnapshot`는 네트워크 경계를 넘는 스냅샷(Sendable)으로 남고,
/// 이 클래스는 MainActor 위 화면용이다.
///
/// 변경은 `CardStore`를 거친다. 프로퍼티가 열려 있지만 뷰에서 직접 고치면
/// 서버 동기화를 건너뛰게 된다.
@MainActor
@Observable
final class Card: Identifiable {
    /// 서버가 부여한 정체성. `Identifiable.id`로도 쓴다.
    let captureID: Int64

    var title: String
    var summary: String
    var collection: CollectionKind
    var organizedAt: Date?
    var location: String
    var businessHours: String
    var confirmationLabel: String?
    var memo: String
    var tags: [String]
    var originalImageAssetName: String?
    var thumbnailAssetName: String?
    var originalImageURL: URL?
    var thumbnailURL: URL?
    var isFavorite: Bool

    var id: Int64 { captureID }

    /// 서버 스냅샷에서 만든다.
    init(snapshot: CardSnapshot) {
        captureID = snapshot.captureID
        title = snapshot.title
        summary = snapshot.summary
        collection = snapshot.collection
        organizedAt = snapshot.organizedAt
        location = snapshot.location
        businessHours = snapshot.businessHours
        confirmationLabel = snapshot.confirmationLabel
        memo = snapshot.memo
        tags = snapshot.tags
        originalImageAssetName = snapshot.originalImageAssetName
        thumbnailAssetName = snapshot.thumbnailAssetName
        originalImageURL = snapshot.originalImageURL
        thumbnailURL = snapshot.thumbnailURL
        isFavorite = snapshot.isFavorite
    }

    /// 재조회로 받은 최신 스냅샷을 반영한다. 정체성(`captureID`)은 바뀌지 않는다.
    func update(from snapshot: CardSnapshot) {
        title = snapshot.title
        summary = snapshot.summary
        collection = snapshot.collection
        organizedAt = snapshot.organizedAt
        location = snapshot.location
        businessHours = snapshot.businessHours
        confirmationLabel = snapshot.confirmationLabel
        memo = snapshot.memo
        tags = snapshot.tags
        originalImageAssetName = snapshot.originalImageAssetName
        thumbnailAssetName = snapshot.thumbnailAssetName
        originalImageURL = snapshot.originalImageURL
        thumbnailURL = snapshot.thumbnailURL
        isFavorite = snapshot.isFavorite
    }
}
