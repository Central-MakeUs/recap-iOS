import Foundation

nonisolated struct OpenSourceLicense: Hashable, Identifiable, Sendable {
    let name: String
    let body: String

    var id: String { name }
}

/// 번들에 포함된 `OpenSourceLicenses.plist`에서 오픈소스 라이선스를 읽는다.
///
/// 파일은 LicensePlist(singlePage)로 생성해 커밋한다. 의존성이 바뀌면 재생성한다:
/// `license-plist --config-path license_plist.yml --single-page --output-path /tmp/lp`
/// 후 `/tmp/lp/com.mono0926.LicensePlist.plist`를 `Recap/Resources/OpenSourceLicenses.plist`로 교체.
nonisolated struct OpenSourceLicenseLoader {
    private enum Key {
        static let resourceName = "OpenSourceLicenses"
        static let specifiers = "PreferenceSpecifiers"
        static let title = "Title"
        static let footerText = "FooterText"
    }

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadLicenses() -> [OpenSourceLicense] {
        guard
            let url = bundle.url(forResource: Key.resourceName, withExtension: "plist"),
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

        return specifiers.compactMap { specifier in
            guard
                let name = specifier[Key.title] as? String,
                let body = (specifier[Key.footerText] as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !body.isEmpty
            else {
                return nil
            }

            return OpenSourceLicense(name: name, body: body)
        }
    }
}
