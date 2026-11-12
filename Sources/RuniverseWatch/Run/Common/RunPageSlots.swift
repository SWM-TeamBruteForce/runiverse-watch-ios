import CoreGraphics

/// 장 공통 줄 높이(화면 위에서 pt)다. 큰 숫자 높이로 잡아 장을 넘겨도 줄이 제자리에 있다.
struct RunPageSlots: Equatable {
    /// 위 줄 잉크의 아랫변이다.
    let topRowBottom: CGFloat
    /// 큰 숫자 잉크의 세로 가운데다.
    let center: CGFloat
    /// 큰 숫자의 기준선이다. 숫자 잉크는 기준선 아래로 내려가지 않는다.
    let bigNumberBaseline: CGFloat
    /// 큰 숫자 아래 줄(사진·솔로 심박)의 윗변이다.
    let belowRowTop: CGFloat
    /// 맨 아래 줄(격차·연결 안내) 잉크의 윗변이다.
    let bottomRowTop: CGFloat

    // 시계 자리는 앱이 알 수 없고 기기마다 달라, 첫 화면 묶음을 시스템 안전 영역 세로 가운데에 둔다
    init(screen: WatchScreen, sizes: WatchFontSizes) {
        let numeral = SUITFont.numeralInk.aboveBaselineEm
        let halfBigNumber = sizes.bigNumber * numeral / 2
        let topRowHeight = sizes.value * numeral
        // 콤보가 아닐 때도 고리 자리를 비워 둬 고리가 생겨도 아래 줄이 안 움직인다
        let avatarRowHeight =
            RunDimensions.avatarSize + RunDimensions.comboBorderWidth + RunDimensions.avatarToBottomRowGap
        let bottomRowHeight = sizes.reading * numeral
        let aboveCenter = halfBigNumber + RunDimensions.groupGap + topRowHeight
        let belowCenter = halfBigNumber + RunDimensions.groupGap + avatarRowHeight + bottomRowHeight
        center = (screen.safeAreaTop + aboveCenter + screen.safeAreaBottom - belowCenter) / 2
        topRowBottom = center - halfBigNumber - RunDimensions.groupGap
        bigNumberBaseline = center + halfBigNumber
        belowRowTop = bigNumberBaseline + RunDimensions.groupGap
        bottomRowTop = belowRowTop + avatarRowHeight
    }
}
