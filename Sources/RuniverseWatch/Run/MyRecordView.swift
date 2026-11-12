import SwiftUI

/// 러닝 중 내 기록 장이다. 가운데 심박을 크게, 그 아래 구간 막대와 케이던스·칼로리를 둔다.
struct MyRecordView: View {
    let run: RunState
    let isPhoneReachable: Bool
    let heartRateBpm: Int?
    let birthday: String?

    var body: some View {
        let content = MyRecordContent(
            run: run,
            isPhoneReachable: isPhoneReachable,
            heartRateBpm: heartRateBpm,
            birthday: birthday,
            today: HeartRateZone.today()
        )
        ScreenLayoutView { screen in
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let pageSlots = RunPageSlots(screen: screen, sizes: sizes)
            let slots = MyRecordSlots(screen: screen, sizes: sizes, showsZoneBar: content.heartRateZone != nil)
            if let progress = content.progress {
                ProgressRingView(
                    progress: progress,
                    color: LaneColors.color(colorSlot: LaneColors.myColorSlot),
                    screen: screen
                )
                .opacity(content.phoneValuesAlpha)
            }
            if let notice = content.topNotice {
                AlignedTextView(
                    notice,
                    size: sizes.reading,
                    color: RuniverseColors.value,
                    placement: .bottom(pageSlots.topRowBottom)
                )
            }
            // 심박은 워치가 재는 값이라 폰이 끊겨도 흐리지 않는다
            ValueWithUnitView(
                content.heartRateText,
                unit: RunTexts.heartRateUnit,
                valueSize: sizes.bigNumber,
                valueWeight: .bold,
                monospacesDigits: true,
                valueColor: .white,
                placement: .bottom(slots.heartRateBottom)
            )
            if let zone = content.heartRateZone {
                HeartRateZoneBarView(filledZoneCount: zone, valueSize: sizes.bigNumber, valueWeight: .bold)
                    .alignmentGuide(.top) { _ in -slots.zoneBarTop }
            }
            RecordRows(content: content, sizes: sizes, slots: slots)
                .opacity(content.phoneValuesAlpha)
        }
    }
}

/// 내 기록 장이 그릴 값이다.
struct MyRecordContent: Equatable {
    /// 목표가 없으면(솔로) nil — 링을 그리지 않는다.
    let progress: Double?
    /// 폰이 끊기면 폰에서 받은 값을 마지막 값에서 멈춘 채 흐리게 둔다.
    let phoneValuesAlpha: Double
    /// 위 줄 자리에 쓰는 안내다. 같은 자리라 끊김 안내가 멈춤보다 먼저다.
    let topNotice: String?
    let heartRateText: String
    /// 생일이 없으면 nil — 막대를 숨긴다.
    let heartRateZone: Int?
    let cadenceText: String
    let caloriesText: String

    init(run: RunState, isPhoneReachable: Bool, heartRateBpm: Int?, birthday: String?, today: DateComponents) {
        progress = RunFormat.distanceProgress(run.me.distanceMeters, targetDistanceMeters: run.targetDistanceMeters)
        phoneValuesAlpha = isPhoneReachable ? 1 : RunDimensions.staleContentAlpha
        if !isPhoneReachable {
            topNotice = String(localized: "run_phone_checking", bundle: .module)
        } else if run.status == .paused {
            topNotice = RunTexts.paused
        } else {
            topNotice = nil
        }
        heartRateText = heartRateBpm.map(String.init) ?? RunTexts.valueUnknown
        heartRateZone = HeartRateZone.calculate(
            heartRateBpm: heartRateBpm,
            birthday: HeartRateZone.parseBirthday(birthday),
            today: today
        )
        // 폰이 아직 안 보낸 값은 값 없음으로 둔다
        cadenceText = run.me.cadenceSpm.map(String.init) ?? RunTexts.valueUnknown
        caloriesText = run.me.caloriesKcal.map(String.init) ?? RunTexts.valueUnknown
    }
}

/// 내 기록 장 자리(화면 위 끝에서 pt)다. 심박 기준선은 장 공통 큰 숫자 기준선이다.
struct MyRecordSlots: Equatable {
    /// 심박 덩어리 잉크의 아랫변이다 — 숫자가 아니라 `bpm`의 p 꼬리 아래다.
    let heartRateBottom: CGFloat
    let zoneBarTop: CGFloat
    /// 케이던스·칼로리 첫 줄 잉크의 윗변이다.
    let recordRowsTop: CGFloat
    /// 가장 넓은 케이던스·칼로리가 한 줄에 들어간다. 값이 아니라 화면으로 정해 달리는 중 모양이 안 바뀐다.
    let recordsFitOneLine: Bool

    init(screen: WatchScreen, sizes: WatchFontSizes, showsZoneBar: Bool) {
        let pageSlots = RunPageSlots(screen: screen, sizes: sizes)
        // 숫자든 `--`든 잉크 높이가 같아 심박 값과 상관없이 잰다
        let heartRateInk = ValueWithUnitView.ink(
            value: RunTexts.valueUnknown,
            unit: RunTexts.heartRateUnit,
            valueSize: sizes.bigNumber
        )
        heartRateBottom = pageSlots.bigNumberBaseline + heartRateInk.below
        zoneBarTop = heartRateBottom + RunDimensions.valueToZoneBarGap
        // 생일이 없어 막대를 숨기면 그 자리도 비우지 않고 심박 바로 아래에서 잰다
        let aboveRows = showsZoneBar ? zoneBarTop + RunDimensions.zoneBarHeight : heartRateBottom
        recordRowsTop = aboveRows + RunDimensions.groupGap
        let widestRowWidth =
            ValueWithUnitView.width(
                Self.widestCadence,
                unit: RunTexts.cadenceUnit,
                valueSize: sizes.value,
                monospacesDigits: true
            )
            + RunDimensions.groupGap
            + ValueWithUnitView.width(
                Self.widestCalories,
                unit: RunTexts.caloriesUnit,
                valueSize: sizes.value,
                monospacesDigits: true
            )
        let firstBaseline = recordRowsTop + sizes.value * SUITFont.numeralInk.aboveBaselineEm
        recordsFitOneLine =
            widestRowWidth <= screen.usableWidth(atY: firstBaseline, margin: RunDimensions.textEdgeMargin)
    }

    // 같은 폭 숫자라도 SUIT는 1 다음 1에 자간이 붙어, 11이 가장 많은 값이 가장 넓다
    private static let widestCadence = "111"
    private static let widestCalories = "1111"
}

private struct RecordRows: View {
    let content: MyRecordContent
    let sizes: WatchFontSizes
    let slots: MyRecordSlots

    var body: some View {
        let cadence = ValueWithUnitView(
            content.cadenceText,
            unit: RunTexts.cadenceUnit,
            valueSize: sizes.value,
            monospacesDigits: true
        )
        let calories = ValueWithUnitView(
            content.caloriesText,
            unit: RunTexts.caloriesUnit,
            valueSize: sizes.value,
            monospacesDigits: true
        )
        let cadenceInk = ValueWithUnitView.ink(
            value: content.cadenceText,
            unit: RunTexts.cadenceUnit,
            valueSize: sizes.value
        )
        if slots.recordsFitOneLine {
            HStack(alignment: .firstTextBaseline, spacing: RunDimensions.groupGap) {
                cadence
                calories
            }
            .alignmentGuide(.top) { $0[.firstTextBaseline] - (slots.recordRowsTop + cadenceInk.above) }
        } else {
            cadence
                .alignmentGuide(.top) { $0[.firstTextBaseline] - (slots.recordRowsTop + cadenceInk.above) }
            // 둘째 줄은 `spm`의 p 꼬리 아래에서 줄 간격만큼 띄운다
            let caloriesTop = slots.recordRowsTop + cadenceInk.above + cadenceInk.below + RunDimensions.lineGap
            let caloriesInk = ValueWithUnitView.ink(
                value: content.caloriesText,
                unit: RunTexts.caloriesUnit,
                valueSize: sizes.value
            )
            calories
                .alignmentGuide(.top) { $0[.firstTextBaseline] - (caloriesTop + caloriesInk.above) }
        }
    }
}

#Preview("내 기록 장 달리는 중") {
    MyRecordView(run: RunSamples.party, isPhoneReachable: true, heartRateBpm: 148, birthday: RunSamples.birthday)
}

#Preview("내 기록 장 폰 끊김") {
    MyRecordView(run: RunSamples.party, isPhoneReachable: false, heartRateBpm: 148, birthday: RunSamples.birthday)
}

#Preview("내 기록 장 멈춤") {
    MyRecordView(run: RunSamples.paused, isPhoneReachable: true, heartRateBpm: 92, birthday: RunSamples.birthday)
}

#Preview("내 기록 장 심박·생일 없음") {
    MyRecordView(run: RunSamples.solo, isPhoneReachable: true, heartRateBpm: nil, birthday: nil)
}
