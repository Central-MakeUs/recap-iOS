import Foundation
import KakaoSDKAuth
import KakaoSDKCommon

enum KakaoSDKBootstrap {
    @discardableResult
    static func initialize(configuration: AppConfiguration) -> Bool {
        initialize(appKey: configuration.kakaoNativeAppKey)
    }

    @discardableResult
    static func initialize(appKey: String?) -> Bool {
        guard let appKey = appKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !appKey.isEmpty else {
            return false
        }

        KakaoSDK.initSDK(appKey: appKey)
        return true
    }

    @MainActor
    static func handleOpenURL(_ url: URL) -> Bool {
        AuthController.handleOpenUrl(url: url)
    }
}
