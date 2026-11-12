import CoreGraphics

/// 장 공통 줄 자리(화면 위에서 pt)다. 큰 숫자 높이로 잡아 장을 넘겨도 줄이 제자리에 있다.
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

    /// 위 줄 왼쪽 끝(거리)부터 오른쪽 끝(시간·이름)까지다. 첫 화면 가장 넓은 값으로 잰다.
    /// 글자 폭을 재는 일이라 줄 자리에 담지 않고, 위 줄을 그리는 장만 부른다.
    static func topRowWidth(sizes: WatchFontSizes) -> CGFloat {
        let widestDistance = ValueWithUnitView.width(
            Self.widestDistance,
            unit: RunTexts.kilometerUnit,
            valueSize: sizes.value,
            monospacesDigits: true
        )
        let widestTime = SUITFont.width(
            of: Self.widestElapsedTime,
            size: sizes.value,
            weight: .semiBold,
            monospacesDigits: true
        )
        return widestDistance + Self.minDistanceToTimeGap + widestTime
    }

    // 같은 폭 숫자라도 SUIT는 1 다음 1에 자간이 붙어, 11이 가장 많은 값이 가장 넓다
    private static let widestDistance = "11.1"
    private static let widestElapsedTime = "1:11:11"
    private static let minDistanceToTimeGap: CGFloat = 13
}
