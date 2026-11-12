import SwiftUI

/// 화면 크기와 시스템 안전 영역(pt)이다. 높이는 모두 화면 위 끝에서 잰다.
struct WatchScreen: Equatable {
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    /// 시계 같은 시스템 자리를 뺀, 내용을 두는 영역의 위 끝이다.
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat
}

extension WatchScreen {
    /// 화면 모서리 반지름이다.
    var cornerRadius: CGFloat { screenWidth * Self.cornerToWidthRatio }

    // 시안 그림에서 잰 추정값이다
    private static let cornerToWidthRatio: CGFloat = 0.165

    /// 안전 영역을 따르는 GeometryReader에서 잰다.
    init(_ proxy: GeometryProxy) {
        let insets = proxy.safeAreaInsets
        self.init(
            screenWidth: proxy.size.width + insets.leading + insets.trailing,
            screenHeight: proxy.size.height + insets.top + insets.bottom,
            safeAreaTop: insets.top,
            safeAreaBottom: insets.top + proxy.size.height
        )
    }
}
