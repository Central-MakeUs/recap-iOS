import Observation
import SwiftUI

/// 로그인·온보딩·서버 호출 없이, 번들 fixture만으로 기존 앱 흐름을 보여 주는 진입점.
struct DemoRootView: View {
    @State private var model = DemoAppModel()
    @State private var isUploadUnavailablePresented = false

    var body: some View {
        AppShellView(
            router: model.router,
            cardStore: model.cardStore,
            homeSummaryLoader: model.homeSummaryLoader,
            archiveLoader: model.archiveLoader,
            searchLoader: model.searchLoader,
            captureService: model.captureService,
            userAccountService: model.userAccountService,
            cardCreationProcessor: model.cardCreationProcessor,
            cardDataInvalidationCenter: model.invalidationCenter,
            organizeNotificationStore: model.organizeNotificationStore,
            aiDataTransferConsentStore: model.aiDataTransferConsentStore,
            onUploadRequested: { isUploadUnavailablePresented = true }
        )
        .alert("데모 앱에서는 새 스크린샷을 정리할 수 없어요", isPresented: $isUploadUnavailablePresented) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("미리 준비된 20개의 정리 결과를 둘러볼 수 있어요.")
        }
    }
}

@MainActor
@Observable
private final class DemoAppModel {
    let router = AppRouter()
    let invalidationCenter = CardDataInvalidationCenter()
    let cardStore: CardStore
    let homeSummaryLoader: DemoHomeSummaryLoader
    let archiveLoader: DemoArchiveLoader
    let searchLoader: DemoSearchLoader
    let captureService: DemoCaptureService
    let userAccountService: DemoUserAccountService
    let cardCreationProcessor = DemoCardCreationProcessor()
    let organizeNotificationStore = OrganizeNotificationStore()
    let aiDataTransferConsentStore = AIDataTransferConsentStore(
        service: DemoAIDataTransferConsentService()
    )

    init() {
        let repository = DemoFixtureRepository.loadFromBundle()
        let captureService = DemoCaptureService(repository: repository)

        self.captureService = captureService
        cardStore = CardStore(
            captureMutator: captureService,
            invalidationCenter: invalidationCenter
        )
        homeSummaryLoader = DemoHomeSummaryLoader(repository: repository)
        archiveLoader = DemoArchiveLoader(repository: repository)
        searchLoader = DemoSearchLoader(repository: repository)
        userAccountService = DemoUserAccountService(repository: repository)
    }
}

#if DEBUG
#Preview {
    DemoRootView()
}
#endif
