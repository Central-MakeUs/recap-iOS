import XCTest
@testable import Recap

@MainActor
final class OrganizeNotificationStoreTests: XCTestCase {
    func testToggleEnablesPreferenceAfterSystemAuthorization() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .authorized)
        let fixture = makeFixture(delivery: delivery)

        let action = await fixture.controller.toggleOrganizeNotifications()

        XCTAssertEqual(action, .none)
        XCTAssertTrue(fixture.controller.isPreferenceEnabled)
        XCTAssertTrue(fixture.controller.isEnabled)
        XCTAssertTrue(fixture.userDefaults.bool(forKey: fixture.preferenceKey))
    }

    func testFirstOrganizeShowsPermissionGuideBeforeRequestingSystemPermission() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .notDetermined)
        let fixture = makeFixture(
            delivery: delivery,
            storedPreference: nil
        )

        let shouldPresentGuide = await fixture.controller.shouldPresentPermissionGuide()
        await fixture.controller.prepareForOrganize()

        let requestCount = await delivery.authorizationRequestCount()
        XCTAssertTrue(shouldPresentGuide)
        XCTAssertEqual(requestCount, 0)
        XCTAssertFalse(fixture.controller.isEnabled)
        XCTAssertNil(fixture.userDefaults.object(forKey: fixture.preferenceKey))
    }

    func testPermissionGuideIsNotPresentedAgainAfterBeingDeclined() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .notDetermined)
        let fixture = makeFixture(delivery: delivery, storedPreference: nil)

        let firstVisit = await fixture.controller.shouldPresentPermissionGuide()
        fixture.controller.declinePermissionGuide()
        let secondVisit = await fixture.controller.shouldPresentPermissionGuide()

        XCTAssertTrue(firstVisit)
        XCTAssertFalse(secondVisit, "안내는 최초 1회만 노출돼야 한다")
        XCTAssertFalse(fixture.userDefaults.bool(forKey: fixture.preferenceKey))
    }

    /// "나중에 하기"는 끔으로 저장된다. 설정 화면에서 다시 켤 수 있어야 한다.
    func testDeclinedPermissionGuideCanBeEnabledFromSettings() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .notDetermined)
        let fixture = makeFixture(delivery: delivery, storedPreference: nil)

        _ = await fixture.controller.shouldPresentPermissionGuide()
        fixture.controller.declinePermissionGuide()
        XCTAssertFalse(fixture.controller.isEnabled)

        await delivery.setStatus(.authorized)
        let action = await fixture.controller.toggleOrganizeNotifications()

        XCTAssertEqual(action, .none)
        XCTAssertTrue(fixture.controller.isEnabled)
    }

    func testPermissionGuideConfirmationRequestsPermissionAndEnablesPreference() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .notDetermined)
        let fixture = makeFixture(
            delivery: delivery,
            storedPreference: nil
        )

        await fixture.controller.requestPermissionForOrganize()

        let requestCount = await delivery.authorizationRequestCount()
        XCTAssertEqual(requestCount, 1)
        XCTAssertTrue(fixture.controller.isEnabled)
        XCTAssertTrue(fixture.userDefaults.bool(forKey: fixture.preferenceKey))
    }

    func testFirstOrganizeUsesExistingSystemPermissionWhenPreferenceWasNeverStored() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .authorized)
        let fixture = makeFixture(
            delivery: delivery,
            storedPreference: nil
        )

        await fixture.controller.prepareForOrganize()

        let requestCount = await delivery.authorizationRequestCount()
        XCTAssertEqual(requestCount, 0)
        XCTAssertTrue(fixture.controller.isEnabled)
    }

    func testFirstOrganizeDoesNotOverrideExplicitlyDisabledPreference() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .authorized)
        let fixture = makeFixture(
            delivery: delivery,
            storedPreference: false
        )

        await fixture.controller.prepareForOrganize()

        XCTAssertFalse(fixture.controller.isPreferenceEnabled)
        XCTAssertFalse(fixture.controller.isEnabled)
    }

    func testDeniedToggleEnablesPreferenceAfterReturningFromSystemSettings() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .denied)
        let fixture = makeFixture(delivery: delivery)

        let action = await fixture.controller.toggleOrganizeNotifications()
        XCTAssertEqual(action, .openSettings)
        XCTAssertFalse(fixture.controller.isEnabled)

        await delivery.setStatus(.authorized)
        await fixture.controller.refreshAuthorization()

        XCTAssertTrue(fixture.controller.isPreferenceEnabled)
        XCTAssertTrue(fixture.controller.isEnabled)
    }

    func testBackgroundTerminalResultDeliversNotification() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .authorized)
        let fixture = makeFixture(delivery: delivery, isEnabled: true)
        fixture.controller.setApplicationInBackground(true)

        await fixture.controller.notifyOrganizeResult(
            OrganizeStatusResponseDTO(
                batchId: 42,
                status: .partialFailed,
                totalCount: 3,
                successCount: 2,
                failCount: 1
            )
        )

        let messages = await delivery.deliveredMessages()
        XCTAssertEqual(
            messages,
            [
                OrganizeNotificationMessage(
                    identifier: "recap.organize.result.42",
                    title: "스크린샷 정리가 끝났어요",
                    body: "2개를 정리하고 1개를 정리하지 못했어요."
                )
            ]
        )
    }

    func testForegroundResultDoesNotDeliverNotification() async {
        let delivery = OrganizeNotificationDeliverySpy(status: .authorized)
        let fixture = makeFixture(delivery: delivery, isEnabled: true)

        await fixture.controller.notifyOrganizeResult(
            OrganizeStatusResponseDTO(
                batchId: 42,
                status: .completed,
                totalCount: 1,
                successCount: 1,
                failCount: 0
            )
        )

        let messages = await delivery.deliveredMessages()
        XCTAssertTrue(messages.isEmpty)
    }

    func testCardCreationBalancesBackgroundExecutionAroundOrganizeRequest() async {
        let backgroundExecution = OrganizeBackgroundExecutionSpy()
        let viewModel = CardCreationFlowViewModel(
            processor: ImmediateCardCreationProcessor(),
            backgroundExecution: backgroundExecution
        )
        viewModel.receivePickerSelection(
            imageData: [Data([0x01])],
            failedCount: 0,
            appending: false
        )

        await viewModel.processSelectedScreenshots()

        XCTAssertEqual(backgroundExecution.beginCount, 1)
        XCTAssertEqual(backgroundExecution.endCount, 1)
    }

    private func makeFixture(
        delivery: OrganizeNotificationDeliverySpy,
        isEnabled: Bool = false,
        storedPreference: Bool? = false
    ) -> (
        controller: OrganizeNotificationStore,
        userDefaults: UserDefaults,
        preferenceKey: String
    ) {
        let suiteName = "OrganizeNotificationStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let preferenceKey = "organize-notification-enabled"
        if let storedPreference {
            userDefaults.set(storedPreference || isEnabled, forKey: preferenceKey)
        }

        return (
            OrganizeNotificationStore(
                delivery: delivery,
                userDefaults: userDefaults,
                preferenceKey: preferenceKey
            ),
            userDefaults,
            preferenceKey
        )
    }
}

@MainActor
private final class OrganizeBackgroundExecutionSpy: OrganizeBackgroundExecuting {
    private(set) var beginCount = 0
    private(set) var endCount = 0

    func begin() {
        beginCount += 1
    }

    func end() {
        endCount += 1
    }
}

private actor ImmediateCardCreationProcessor: CardCreationProcessing {
    func process(
        images: [Data],
        progress: @escaping @MainActor @Sendable (CardCreationProgress) -> Void
    ) async throws -> OrganizeStatusResponseDTO {
        await progress(.init(phase: .completed, fractionCompleted: 1))
        return OrganizeStatusResponseDTO(
            batchId: 1,
            status: .completed,
            totalCount: images.count,
            successCount: images.count,
            failCount: 0
        )
    }

    func cancelCurrentProcess() async {}
}

private actor OrganizeNotificationDeliverySpy: OrganizeNotificationDelivering {
    private var status: OrganizeNotificationAuthorizationStatus
    private var messages: [OrganizeNotificationMessage] = []
    private var requestCount = 0

    init(status: OrganizeNotificationAuthorizationStatus) {
        self.status = status
    }

    func authorizationStatus() async -> OrganizeNotificationAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> Bool {
        requestCount += 1
        status = .authorized
        return true
    }

    func deliver(_ message: OrganizeNotificationMessage) async throws {
        messages.append(message)
    }

    func setStatus(_ status: OrganizeNotificationAuthorizationStatus) {
        self.status = status
    }

    func deliveredMessages() -> [OrganizeNotificationMessage] {
        messages
    }

    func authorizationRequestCount() -> Int {
        requestCount
    }
}
