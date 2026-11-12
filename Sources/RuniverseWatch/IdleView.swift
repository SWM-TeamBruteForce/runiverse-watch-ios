import SwiftUI

/// 러닝이 없을 때 화면이다.
/// 글자 두 줄은 업데이트 필요 화면과 같은 자리라, 폰이 버전을 거절해 넘어가도 글자가 제자리에서 바뀐다.
struct IdleView: View {
    /// nil이면 폰이 켠 러닝을 기다리며 그림만 그린다.
    let content: IdleContent?

    var body: some View {
        ScreenLayoutView { screen in
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let center = RunPageSlots(screen: screen, sizes: sizes).center
            let titleBottom = center - RunDimensions.groupGap / 2
            // 첫 줄이 없어도 그림이 같은 자리에 있게, 첫 줄 높이는 문구가 아니라 한글 잉크로 잰다
            let hangulInk = SUITFont.hangulInk
            let titleTop = titleBottom - (hangulInk.aboveBaselineEm + hangulInk.belowBaselineEm) * sizes.reading
            let markTop = titleTop - RunDimensions.groupGap - Self.markHeight
            Image("RuniverseMark", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(height: Self.markHeight)
                .alignmentGuide(.top) { _ in -markTop }
                .accessibilityLabel(Text(verbatim: "Runiverse"))
            if let content {
                AlignedTextView(
                    content.title,
                    size: sizes.reading,
                    color: RuniverseColors.value,
                    placement: .bottom(titleBottom)
                )
            }
            if let subtitle = content?.subtitle {
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
    IdleView(content: IdleContent(isPhoneReachable: true))
}

#Preview("대기 화면 연결 확인 중") {
    IdleView(content: IdleContent(isPhoneReachable: false))
}

#Preview("대기 화면 폰이 켠 러닝 기다림") {
    IdleView(content: nil)
}
