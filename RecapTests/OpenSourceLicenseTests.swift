import XCTest
@testable import Recap

@MainActor
final class OpenSourceLicenseTests: XCTestCase {
    /// LicensePlistBuildTool이 앱 번들에 넣은 plist를 실제로 읽어내는지 확인한다.
    /// 플러그인이 동작하지 않으면 목록이 비어 이 테스트가 실패한다.
    func testLoaderReadsGeneratedLicensesFromAppBundle() {
        let licenses = OpenSourceLicenseLoader().loadLicenses()

        XCTAssertFalse(
            licenses.isEmpty,
            "LicensePlistBuildTool 출력이 앱 번들에 없습니다. 플러그인 설정을 확인해주세요."
        )

        for license in licenses {
            XCTAssertFalse(license.name.isEmpty)
            XCTAssertFalse(
                license.body.isEmpty,
                "\(license.name)의 라이선스 본문이 비어 있습니다."
            )
        }
    }

    /// 앱이 실제로 링크하는 라이브러리가 목록에 포함되어야 한다.
    /// 이름에는 `addVersionNumbers` 옵션으로 버전이 덧붙으므로 접두사로 확인한다.
    func testLoaderIncludesLinkedDependencies() {
        let names = OpenSourceLicenseLoader().loadLicenses().map(\.name)

        for expected in ["Alamofire", "KakaoOpenSDK", "Lottie"] {
            XCTAssertTrue(
                names.contains { $0.hasPrefix(expected) },
                "\(expected)이 없습니다. 실제 목록: \(names.sorted())"
            )
        }
    }

    /// LicensePlist 자신과 그 빌드 도구 의존성은 앱에 포함되지 않으므로 제외되어야 한다.
    func testLoaderExcludesBuildToolOnlyDependencies() {
        let names = Set(OpenSourceLicenseLoader().loadLicenses().map(\.name))
        let buildToolOnly = ["LicensePlist", "Yams", "XcodeEdit", "APIKit", "swift-argument-parser"]

        for name in buildToolOnly {
            XCTAssertFalse(
                names.contains(name),
                "\(name)은 빌드 도구 전용이므로 license_plist.yml에서 제외해야 합니다."
            )
        }
    }
}
