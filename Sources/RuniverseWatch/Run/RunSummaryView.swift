import SwiftUI

/// 끝난 러닝의 결과 요약이다.
struct RunSummaryView: View {
    let content: RunSummaryContent
    let onClose: () -> Void

    var body: some View {
        ScreenLayoutView { screen in
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let slots = RunSummarySlots(screen: screen, sizes: sizes)
            AlignedTextView(
                content.title,
                size: sizes.reading,
                color: content.isResultStuck ? RuniverseColors.value : RuniverseColors.supporting,
                placement: .bottom(slots.titleBottom)
            )
            ValueWithUnitView(
                content.distanceText,
                unit: RunTexts.kilometerUnit,
                valueSize: sizes.bigNumber,
                valueWeight: .bold,
                valueColor: .white,
                placement: .bottom(slots.bigNumberBaseline)
            )
            .opacity(content.valuesAlpha)
            TimePaceRow(content: content, sizes: sizes, screenWidth: screen.screenWidth, inkTop: slots.timePaceRowTop)
                .opacity(content.valuesAlpha)
            ControlButton(label: content.closeLabel, icon: .check, fontSize: sizes.reading, action: onClose)
                .padding(.bottom, ControlButton.bottomPadding)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

/// 결과 요약이 그릴 값이다.
struct RunSummaryContent: Equatable {
    /// 결과를 받는 중에 폰이 끊겼다. 받은 결과는 더 안 바뀌어 끊겨도 멈춘 것으로 보지 않는다.
    let isResultStuck: Bool
    let title: String
    let distanceText: String
    let elapsedTimeText: String
    let averagePaceText: String
    let valuesAlpha: Double
    let closeLabel = String(localized: "run_summary_close", bundle: .module)

    init(result: RunResult?, isPhoneReachable: Bool) {
        isResultStuck = result == nil && !isPhoneReachable
        title =
            isResultStuck
            ? String(localized: "run_phone_checking", bundle: .module)
            : String(localized: "run_summary_completed", bundle: .module)
        distanceText = result.map { RunFormat.formatRunDistanceKm($0.totalDistanceMeters) } ?? RunTexts.valueUnknown
        elapsedTimeText = result.map { RunFormat.formatElapsedTime($0.elapsedSeconds) } ?? RunTexts.valueUnknown
        averagePaceText = result.map { RunFormat.formatPace($0.averagePaceSecondsPerKm) } ?? RunTexts.valueUnknown
        valuesAlpha = isResultStuck ? RunDimensions.staleContentAlpha : 1
    }
}

/// 결과 요약 자리(화면 위 끝에서 pt)다.
struct RunSummarySlots: Equatable {
    /// 제목 잉크의 아랫변이다.
    let titleBottom: CGFloat
    /// 총거리의 기준선이다. 숫자·km는 기준선 아래로 안 내려간다.
    let bigNumberBaseline: CGFloat
    /// 시간·평균 페이스 잉크의 윗변이다.
    let timePaceRowTop: CGFloat
    /// 닫기 알약의 윗변이다.
    let closeButtonTop: CGFloat

    // 닫기 버튼이 첫 화면 아래 줄 자리까지 올라와, 장 공통 줄 자리 대신 남은 높이 가운데에 묶음을 둔다
    init(screen: WatchScreen, sizes: WatchFontSizes) {
        let hangulInk = SUITFont.hangulInk
        let numeral = SUITFont.numeralInk.aboveBaselineEm
        let titleHeight = sizes.reading * (hangulInk.aboveBaselineEm + hangulInk.belowBaselineEm)
        let bigNumberHeight = sizes.bigNumber * numeral
        let timePaceRowHeight = sizes.value * numeral
        let groupHeight =
            titleHeight + RunDimensions.groupGap + bigNumberHeight + RunDimensions.groupGap + timePaceRowHeight
        closeButtonTop = screen.screenHeight - ControlButton.bottomPadding - ControlButton.pillHeight
        titleBottom = (screen.safeAreaTop + closeButtonTop - groupHeight) / 2 + titleHeight
        bigNumberBaseline = titleBottom + RunDimensions.groupGap + bigNumberHeight
        timePaceRowTop = bigNumberBaseline + RunDimensions.groupGap
    }
}

private struct TimePaceRow: View {
    let content: RunSummaryContent
    let sizes: WatchFontSizes
    let screenWidth: CGFloat
    let inkTop: CGFloat

    var body: some View {
        let baseline = InkPlacement.top(inkTop).baseline(
            ink: SUITFont.ink(for: content.elapsedTimeText + content.averagePaceText),
            size: sizes.value
        )
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            AlignedTextView(content.elapsedTimeText, size: sizes.value, color: RuniverseColors.value)
            Spacer(minLength: 0)
            AlignedTextView(content.averagePaceText, size: sizes.value, color: RuniverseColors.value)
        }
        .frame(width: width)
        .alignmentGuide(.top) { $0[.firstTextBaseline] - baseline }
    }

    // 결과는 받은 뒤 안 바뀌어 가장 넓은 값이 아니라 받은 값으로 잰다
    private var width: CGFloat {
        let timeWidth = SUITFont.width(of: content.elapsedTimeText, size: sizes.value, weight: .semiBold)
        let paceWidth = SUITFont.width(of: content.averagePaceText, size: sizes.value, weight: .semiBold)
        return max(screenWidth * Self.minWidthFraction, timeWidth + Self.minTimeToPaceGap + paceWidth)
    }

    private static let minWidthFraction: CGFloat = 270 / 480
    private static let minTimeToPaceGap: CGFloat = 10
}

#Preview("결과 요약 받음") {
    RunSummaryView(content: RunSummaryContent(result: RunSamples.result, isPhoneReachable: true), onClose: {})
}

#Preview("결과 요약 긴 값") {
    RunSummaryView(content: RunSummaryContent(result: RunSamples.longResult, isPhoneReachable: true), onClose: {})
}

#Preview("결과 요약 받는 중") {
    RunSummaryView(content: RunSummaryContent(result: nil, isPhoneReachable: true), onClose: {})
}

#Preview("결과 요약 받는 중 폰 끊김") {
    RunSummaryView(content: RunSummaryContent(result: nil, isPhoneReachable: false), onClose: {})
}
