import Foundation

nonisolated struct OpenSourceLicense: Hashable, Identifiable, Sendable {
    let name: String
    let body: String

    var id: String { name }
}

/// LicensePlistBuildTool이 빌드 시 앱 번들에 넣어 둔 plist를 읽는다.
///
/// 출력 구조는 iOS 설정 앱의 Settings.bundle 형식을 따른다.
/// - 루트: `com.mono0926.LicensePlist.Output/com.mono0926.LicensePlist.plist`
///   `PreferenceSpecifiers` 중 `PSChildPaneSpecifier` 항목이 라이브러리 하나에 대응하며,
///   `Title`이 이름, `File`이 상세 plist의 상대 경로다.
/// - 상세: 위 `File` 경로의 plist에서 `PreferenceSpecifiers` 첫 항목의 `FooterText`가 라이선스 전문이다.
nonisolated struct OpenSourceLicenseLoader {
    private enum Key {
        static let outputDirectory = "com.mono0926.LicensePlist.Output"
        static let rootPlistName = "com.mono0926.LicensePlist"
        static let specifiers = "PreferenceSpecifiers"
        static let childPaneType = "PSChildPaneSpecifier"
        static let type = "Type"
        static let title = "Title"
        static let file = "File"
        static let footerText = "FooterText"
    }

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadLicenses() -> [OpenSourceLicense] {
        guard let outputDirectory = outputDirectoryURL() else {
            return []
        }

        let rootURL = outputDirectory
            .appendingPathComponent(Key.rootPlistName)
            .appendingPathExtension("plist")

        return Self.childPanes(atRoot: rootURL).compactMap { pane in
            guard
                let name = pane[Key.title] as? String,
                let relativePath = pane[Key.file] as? String,
                let body = Self.licenseBody(
                    at: outputDirectory
                        .appendingPathComponent(relativePath)
                        .appendingPathExtension("plist")
                )
            else {
                return nil
            }

            return OpenSourceLicense(name: name, body: body)
        }
    }

    /// 플러그인 출력은 번들 최상위에 복사된다. 이름에 점이 많아
    /// `url(forResource:withExtension:)`이 확장자를 잘라낼 수 있으므로 번들 경로에서 직접 찾고,
    /// 실패하면 리소스 조회로 한 번 더 시도한다.
    private func outputDirectoryURL() -> URL? {
        let directURL = bundle.bundleURL.appendingPathComponent(Key.outputDirectory)
        if FileManager.default.fileExists(atPath: directURL.path) {
            return directURL
        }

        if let resourceURL = bundle.resourceURL {
            let candidate = resourceURL.appendingPathComponent(Key.outputDirectory)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        if let resourceURL = bundle.url(forResource: Key.outputDirectory, withExtension: nil) {
            return resourceURL
        }

        // SwiftUI 프리뷰에서는 Bundle.main이 앱 번들이 아니므로 로드된 번들을 모두 훑는다.
        for candidateBundle in Bundle.allBundles {
            let candidate = candidateBundle.bundleURL.appendingPathComponent(Key.outputDirectory)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }

    private static func childPanes(atRoot url: URL) -> [[String: Any]] {
        specifiers(at: url).filter { $0[Key.type] as? String == Key.childPaneType }
    }

    private static func licenseBody(at url: URL) -> String? {
        specifiers(at: url)
            .compactMap { $0[Key.footerText] as? String }
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func specifiers(at url: URL) -> [[String: Any]] {
        guard
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any],
            let specifiers = plist[Key.specifiers] as? [[String: Any]]
        else {
            return []
        }

        return specifiers
    }
}
