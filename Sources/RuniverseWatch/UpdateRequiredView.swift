import SwiftUI

/// 폰이 이 워치 버전을 거절했을 때 화면이다. 글자 두 줄은 대기 화면과 같은 자리다.
struct UpdateRequiredView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        let content = UpdateRequiredContent()
        ScreenLayoutView { screen in
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let center = RunPageSlots(screen: screen, sizes: sizes).center
            AlignedTextView(
                content.title,
                size: sizes.reading,
                color: RuniverseColors.value,
                placement: .bottom(center - RunDimensions.groupGap / 2)
            )
            AlignedTextView(
                content.subtitle,
                size: sizes.reading,
                color: RuniverseColors.supporting,
                placement: .top(center + RunDimensions.groupGap / 2)
            )
            ControlButton(label: content.buttonLabel, icon: .upArrow, fontSize: sizes.reading) {
                // 워치OS는 열었는지 앱에 알려 주지 않아, 못 열 때 안내는 시스템 창에 맡긴다
                openURL(Self.storeURL)
            }
            .padding(.bottom, ControlButton.bottomPadding)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    // 워치 앱은 iOS 앱에 담겨 나가 iOS 앱의 스토어 주소를 연다
    // TODO: 스토어 주소 — 실기기에서 워치에 무엇이 열리는지 보고 정한다
    private static let storeURL = URL(string: "https://apps.apple.com/app/id6823043744")!
}

/// 업데이트 필요 화면이 그릴 문구다.
struct UpdateRequiredContent: Equatable {
    let title = String(localized: "update_required", bundle: .module)
    let subtitle = String(localized: "update_cannot_connect", bundle: .module)
    let buttonLabel = String(localized: "update_open_store", bundle: .module)
}

#Preview("업데이트 필요 화면 기본") {
    UpdateRequiredView()
}
