import SwiftUI

/// 화면 전체를 판으로 쓴다. 안의 View는 위 맞춤으로 놓이고, `AlignedTextView`는 화면 위 끝부터 잰 높이에 놓인다.
struct ScreenLayoutView<Content: View>: View {
    @ViewBuilder let content: (WatchScreen) -> Content

    var body: some View {
        GeometryReader { proxy in
            let screen = WatchScreen(proxy)
            ZStack(alignment: .top) {
                // 판을 화면 크기로 채운다 — 없으면 글자 묶음만 한 판이 화면 가운데로 가 높이가 틀어진다
                Color.clear
                content(screen)
            }
            .frame(width: screen.screenWidth, height: screen.screenHeight)
            .offset(x: -proxy.safeAreaInsets.leading, y: -proxy.safeAreaInsets.top)
        }
    }
}
