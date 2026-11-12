import SwiftUI

/// 목표까지 진행을 레인 색으로 채우는 링이다. 화면 가장자리를 따라 시계 방향으로 돈다.
/// `ScreenLayoutView` 안에 두어 화면 전체를 채운다.
struct ProgressRingView: View {
    let progress: Double
    let color: Color
    let screen: WatchScreen

    var body: some View {
        let slots = ProgressRingSlots(screen: screen)
        let track = ProgressRingTrack(slots: slots)
        ZStack {
            track.stroke(RuniverseColors.progressTrack, lineWidth: ProgressRingSlots.strokeWidth)
            if let trimRange = slots.trimRange(progress: progress) {
                track.trim(from: trimRange.lowerBound, to: trimRange.upperBound)
                    .stroke(color, style: StrokeStyle(lineWidth: ProgressRingSlots.strokeWidth, lineCap: .round))
            }
        }
        .frame(width: screen.screenWidth, height: screen.screenHeight)
    }
}

/// 진행 링이 지나는 자리(화면 위 끝·왼쪽 끝에서 pt)다.
struct ProgressRingSlots: Equatable {
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let cornerRadius: CGFloat
    /// 오른쪽 변에서 링이 시작하는 높이다.
    let startY: CGFloat
    /// 위쪽 변에서 링이 끝나는 자리다.
    let endX: CGFloat

    // 시계 자리는 앱이 알 수 없어, 오른쪽은 안전 영역 위 끝부터 위쪽은 화면 가운데까지만 그린다
    init(screen: WatchScreen) {
        screenWidth = screen.screenWidth
        screenHeight = screen.screenHeight
        cornerRadius = screen.screenWidth * Self.screenCornerFraction - Self.centerInset
        startY = screen.safeAreaTop
        endX = screen.screenWidth / 2
    }

    /// 시작부터 끝까지 선 길이다. 오른쪽·아래·왼쪽·위 변에 모서리 셋을 더한다.
    var length: CGFloat {
        let inset = Self.centerInset
        let rightSide = screenHeight - inset - cornerRadius - startY
        let bottomSide = screenWidth - (inset + cornerRadius) * 2
        let leftSide = screenHeight - (inset + cornerRadius) * 2
        let topSide = endX - inset - cornerRadius
        return rightSide + bottomSide + leftSide + topSide + .pi * cornerRadius / 2 * 3
    }

    /// 색을 칠할 구간(선 길이에 대한 몫)이다. 진행이 없으면 nil이다.
    /// 둥근 끝은 두께 절반만큼 더 나가, 빈칸을 지키려고 그만큼 안쪽에서 시작·끝낸다.
    func trimRange(progress: Double) -> ClosedRange<CGFloat>? {
        let clamped = min(max(progress, 0), 1)
        guard clamped > 0 else { return nil }
        let capFraction = Self.strokeWidth / 2 / length
        return capFraction...(capFraction + clamped * (1 - capFraction * 2))
    }

    static let strokeWidth: CGFloat = 5
    static let centerInset: CGFloat = 6

    // 화면 모서리 반지름의 화면 폭에 대한 몫이다 — 시안 그림에서 잰 추정값이다
    private static let screenCornerFraction: CGFloat = 0.165
}

private struct ProgressRingTrack: Shape {
    let slots: ProgressRingSlots

    func path(in rect: CGRect) -> Path {
        let inset = ProgressRingSlots.centerInset
        let topLeft = CGPoint(x: inset, y: inset)
        let topRight = CGPoint(x: slots.screenWidth - inset, y: inset)
        let bottomLeft = CGPoint(x: inset, y: slots.screenHeight - inset)
        let bottomRight = CGPoint(x: slots.screenWidth - inset, y: slots.screenHeight - inset)
        var path = Path()
        path.move(to: CGPoint(x: topRight.x, y: slots.startY))
        path.addArc(tangent1End: bottomRight, tangent2End: bottomLeft, radius: slots.cornerRadius)
        path.addArc(tangent1End: bottomLeft, tangent2End: topLeft, radius: slots.cornerRadius)
        path.addArc(tangent1End: topLeft, tangent2End: topRight, radius: slots.cornerRadius)
        path.addLine(to: CGPoint(x: slots.endX, y: inset))
        return path
    }
}

#Preview("진행 링 62%") {
    ScreenLayoutView { screen in
        ProgressRingView(progress: 0.62, color: LaneColors.color(slot: LaneColors.myColorSlot), screen: screen)
    }
}
