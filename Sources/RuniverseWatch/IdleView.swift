import SwiftUI

/// 러닝이 없을 때 화면이다.
/// 글자 두 줄은 업데이트 필요 화면과 같은 자리라, 폰이 버전을 거절해 넘어가도 글자가 제자리에서 바뀐다.
struct IdleView: View {
    let isPhoneReachable: Bool

    var body: some View {
        let content = IdleContent(isPhoneReachable: isPhoneReachable)
        ScreenLayoutView { screen in
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let center = RunPageSlots(screen: screen, sizes: sizes).center
            let titleBottom = center - RunDimensions.groupGap / 2
            let titleInk = SUITFont.ink(for: content.title)
            let titleTop = titleBottom - (titleInk.aboveBaselineEm + titleInk.belowBaselineEm) * sizes.reading
            let markTop = titleTop - RunDimensions.groupGap - Self.markHeight
            Image("RuniverseMark", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(height: Self.markHeight)
                .alignmentGuide(.top) { _ in -markTop }
                .accessibilityLabel(Text(verbatim: "Runiverse"))
            AlignedTextView(
                content.title,
                size: sizes.reading,
                color: RuniverseColors.value,
                placement: .bottom(titleBottom)
            )
            if let subtitle = content.subtitle {
                AlignedTextView(
                    subtitle,
                    size: sizes.reading,
                    color: RuniverseColors.supporting,
                    placement: .top(center + RunDimensions.groupGap / 2)
                )
            }
        }
    }

    private static let markHeight: CGFloat = 24
}

/// 대기 화면이 그릴 문구다.
struct IdleContent: Equatable {
    let title: String
    /// 폰이 끊겼으면 없다.
    let subtitle: String?

    init(isPhoneReachable: Bool) {
        if isPhoneReachable {
            title = String(localized: "idle_start_on_phone", bundle: .module)
            subtitle = String(localized: "idle_run_screen_shown_automatically", bundle: .module)
        } else {
            title = String(localized: "run_phone_checking", bundle: .module)
            subtitle = nil
        }
    }
}

#Preview("대기 화면 연결됨") {
    IdleView(isPhoneReachable: true)
}

#Preview("대기 화면 연결 확인 중") {
    IdleView(isPhoneReachable: false)
}
