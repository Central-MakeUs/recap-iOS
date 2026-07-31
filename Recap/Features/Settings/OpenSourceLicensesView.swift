import SwiftUI

struct OpenSourceLicensesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var licenses: [OpenSourceLicense]
    @State private var selectedLicense: OpenSourceLicense?

    init(licenses: [OpenSourceLicense] = OpenSourceLicenseLoader().loadLicenses()) {
        _licenses = State(initialValue: licenses)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsNavigationHeader(
                    title: "오픈소스 라이선스",
                    dismiss: { dismiss() }
                )

                if licenses.isEmpty {
                    Text("표시할 오픈소스 라이선스가 없어요.")
                        .font(SettingsTypography.body)
                        .foregroundStyle(Color.recapGray500)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, SettingsLayout.horizontalPadding)
                        .padding(.top, 25)
                } else {
                    VStack(spacing: 0) {
                        ForEach(licenses) { license in
                            SettingsNavigationRow(title: license.name) {
                                selectedLicense = license
                            }
                        }
                    }
                    .padding(.horizontal, SettingsLayout.horizontalPadding)
                    .padding(.top, 15)
                }
            }
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedLicense) { license in
            OpenSourceLicenseDetailView(license: license)
        }
    }
}

private struct OpenSourceLicenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let license: OpenSourceLicense

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsNavigationHeader(
                    title: license.name,
                    dismiss: { dismiss() }
                )

                Text(license.body)
                    .font(RecapFont.pretendard(size: 13, weight: .regular))
                    .foregroundStyle(Color.recapGray500)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, SettingsLayout.horizontalPadding)
                    .padding(.top, 25)
                    .padding(.bottom, 40)
            }
        }
        .background(Color.recapBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview("오픈소스 라이선스") {
    NavigationStack {
        OpenSourceLicensesView(
            licenses: [
                OpenSourceLicense(name: "Alamofire", body: "Copyright (c) 2014-2022 Alamofire Software Foundation\n\nPermission is hereby granted, free of charge, ..."),
                OpenSourceLicense(name: "KakaoOpenSDK", body: "Apache License\nVersion 2.0, January 2004\n..."),
                OpenSourceLicense(name: "Lottie", body: "Apache License\nVersion 2.0, January 2004\n...")
            ]
        )
    }
}

#Preview("오픈소스 라이선스 - 없음") {
    NavigationStack {
        OpenSourceLicensesView(licenses: [])
    }
}
