import SwiftUI

/// Figma 아트보드 높이. 세로 좌표는 모두 이 높이를 전제로 적혀 있다.
enum DesignHeight {
    static let reference: CGFloat = 812
}

private struct DesignHeightScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    /// 화면 높이 ÷ 812.
    ///
    /// SE(667)는 0.82, iPhone 16(852)은 1.05, Pro Max(956)는 1.18이다.
    /// 세로 여백에 곱하면 요소가 화면에서 차지하는 위치의 비율이 기기마다 같아진다.
    var designHeightScale: CGFloat {
        get { self[DesignHeightScaleKey.self] }
        set { self[DesignHeightScaleKey.self] = newValue }
    }
}

extension View {
    /// 화면 높이를 재서 자식들에게 `designHeightScale`을 알린다.
    ///
    /// 세로 여백이 고정이면 화면이 짧을수록 내용이 상대적으로 아래에 놓이고
    /// 길수록 위에 뜬다. 여백만 비율로 늘리고 줄여 그 어긋남을 없앤다.
    /// 요소 크기는 건드리지 않으므로 글자나 동그란 버튼이 찌부되지 않는다.
    func measuringDesignHeightScale() -> some View {
        modifier(DesignHeightScaleReader())
    }

    /// 디자인 기준 세로 여백. 화면 높이 비율만큼 늘리고 줄인다.
    func designScaledTopPadding(_ amount: CGFloat) -> some View {
        modifier(DesignScaledPadding(edge: .top, amount: amount))
    }
}

private struct DesignHeightScaleReader: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .frame(width: proxy.size.width, height: proxy.size.height)
                .environment(
                    \.designHeightScale,
                    proxy.size.height / DesignHeight.reference
                )
        }
    }
}

private struct DesignScaledPadding: ViewModifier {
    @Environment(\.designHeightScale) private var scale

    let edge: Edge.Set
    let amount: CGFloat

    func body(content: Content) -> some View {
        content.padding(edge, amount * scale)
    }
}
