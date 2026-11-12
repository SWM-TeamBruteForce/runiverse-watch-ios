import SwiftUI

/// 러닝 조작 장이다. 안내 두 줄 아래 일시정지·종료가 있고, 스크롤하면 콤보 효과 칸이 나온다.
struct ControlsView: View {
    let run: RunState
    let isPhoneReachable: Bool
    let isComboEffectOn: Bool

    @State private var isScrolled = false

    var body: some View {
        let content = ControlsContent(run: run, isPhoneReachable: isPhoneReachable)
        GeometryReader { proxy in
            let screen = WatchScreen(proxy)
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let slots = ControlsSlots(screen: screen, sizes: sizes)
            // 내용을 화면 위 끝부터 재서 놓는다 — 스크롤하면 시계 밑까지 올라가 덮개로 흐린다
            ZStack(alignment: .top) {
                ScrollView {
                    ControlsItemsView(
                        content: content,
                        isComboEffectOn: isComboEffectOn,
                        isScrolled: isScrolled,
                        screen: screen,
                        sizes: sizes,
                        slots: slots
                    )
                    .onGeometryChange(for: Bool.self) {
                        $0.frame(in: .scrollView).minY < 0
                    } action: {
                        isScrolled = $0
                    }
                }
                ClockFadeView(screen: screen)
            }
            .ignoresSafeArea()
        }
    }
}

/// 스크롤하는 안내·버튼·콤보 칸이다. 자리는 화면 위 끝부터 잰 높이다.
private struct ControlsItemsView: View {
    let content: ControlsContent
    let isComboEffectOn: Bool
    let isScrolled: Bool
    let screen: WatchScreen
    let sizes: WatchFontSizes
    let slots: ControlsSlots

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.frame(width: screen.screenWidth, height: slots.contentHeight)
            if let firstHint = content.firstHint {
                AlignedTextView(
                    firstHint,
                    size: sizes.reading,
                    color: RuniverseColors.value,
                    placement: .top(slots.hintTop)
                )
            }
            if let secondHint = content.secondHint {
                AlignedTextView(
                    secondHint,
                    size: sizes.reading,
                    color: RuniverseColors.supporting,
                    placement: .top(slots.hintTop + slots.hintLineAdvance)
                )
            }
            ControlButton(
                label: content.pauseButton.label,
                icon: content.pauseButton.icon,
                fontSize: sizes.reading,
                width: ControlsSlots.pillWidth
            ) {}
            .alignmentGuide(.top) { _ in -slots.firstButtonTop }
            ControlButton(
                label: content.finishButton.label,
                icon: content.finishButton.icon,
                fontSize: sizes.reading,
                width: ControlsSlots.pillWidth,
                background: LaneColors.color(colorSlot: LaneColors.myColorSlot)
            ) {}
            .alignmentGuide(.top) { _ in -slots.finishButtonTop }
            // 화면 끝에 걸쳐 보이면 조잡해, 통째로 안 들어오면 스크롤할 때까지 숨긴다
            ComboEffectRow(label: content.comboEffectLabel, isOn: isComboEffectOn, fontSize: sizes.reading)
                .opacity(slots.comboRowFits || isScrolled ? 1 : 0)
                .alignmentGuide(.top) { _ in -slots.comboRowTop }
        }
    }
}

/// 스크롤한 내용이 시계와 겹치지 않게 화면 위쪽을 가린다. 시계는 시스템이 이 위에 그린다.
private struct ClockFadeView: View {
    let screen: WatchScreen

    var body: some View {
        // 시계 자리는 앱이 알 수 없어, 안전 영역 위 끝에서 걷히는 높이만큼 위부터 가린다
        let coveredFraction = max(0, screen.safeAreaTop - Self.fadeHeight) / screen.safeAreaTop
        LinearGradient(
            stops: [
                .init(color: .black, location: coveredFraction),
                .init(color: .black.opacity(0), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: screen.screenWidth, height: screen.safeAreaTop)
        .allowsHitTesting(false)
    }

    private static let fadeHeight: CGFloat = 12
}

/// 조작 장이 그릴 값이다.
struct ControlsContent: Equatable {
    /// 남은 거리나 연결 상태다. 흰 글자로 쓴다.
    let firstHint: String?
    /// 첫 안내에 딸린 주의다. 회색으로 쓴다.
    let secondHint: String?
    /// 달리는 중엔 일시정지, 멈췄으면 계속 달리기다.
    let pauseButton: ControlsButtonContent
    let finishButton: ControlsButtonContent
    let comboEffectLabel = String(localized: "controls_combo_effect", bundle: .module)

    init(run: RunState, isPhoneReachable: Bool) {
        let isPaused = run.status == .paused
        pauseButton =
            isPaused
            ? ControlsButtonContent(label: String(localized: "controls_resume", bundle: .module), icon: .play)
            : ControlsButtonContent(label: String(localized: "controls_pause", bundle: .module), icon: .pause)
        // 멈췄으면 이미 한 번 멈춘 뜻이라 한 번에 끝낸다
        finishButton = ControlsButtonContent(
            label: String(localized: isPaused ? "controls_finish" : "controls_hold_to_finish", bundle: .module),
            icon: .stop
        )

        let distanceMeters = run.me.distanceMeters
        // 서버가 답한 남은 거리를 화면 거리보다 먼저 쓴다
        let serverRemainingMeters = run.finish.flatMap { $0.stage == .goalPending ? $0.remainingMeters : nil }
        if let notice = RunTexts.connectionNotice(run: run, isPhoneReachable: isPhoneReachable) {
            firstHint = notice
            secondHint = String(
                localized: isPhoneReachable ? "controls_run_recording" : "controls_after_reconnect",
                bundle: .module
            )
        } else if let serverRemainingMeters {
            firstHint = Self.toGoalHint(serverRemainingMeters)
            secondHint = isPaused ? Self.mayNotComplete : nil
        } else if let targetDistanceMeters = run.targetDistanceMeters {
            let penaltyLineMeters = targetDistanceMeters * Self.penaltyLinePercent / 100
            if distanceMeters >= targetDistanceMeters {
                firstHint = String(localized: "controls_distance_checking", bundle: .module)
                secondHint = isPaused ? nil : String(localized: "controls_keep_running_if_short", bundle: .module)
            } else if run.isPenaltyApplicable, distanceMeters < penaltyLineMeters {
                let remaining = Self.remainingDistanceText(penaltyLineMeters - distanceMeters)
                firstHint = String(localized: "controls_to_penalty_line \(remaining)", bundle: .module)
                secondHint = String(
                    localized: isPaused ? "controls_penalty_if_finished" : "controls_penalty_if_short",
                    bundle: .module
                )
            } else {
                firstHint = Self.toGoalHint(targetDistanceMeters - distanceMeters)
                secondHint = isPaused ? Self.mayNotComplete : nil
            }
        } else {
            // 솔로는 목표가 없어 남은 거리도 주의도 없다
            firstHint = nil
            secondHint = nil
        }
    }

    private static func toGoalHint(_ remainingMeters: Int) -> String {
        String(localized: "controls_to_goal \(remainingDistanceText(remainingMeters))", bundle: .module)
    }

    private static func remainingDistanceText(_ meters: Int) -> String {
        let distance = RunFormat.formatRemainingDistance(meters)
        return distance.value + (RunTexts.distanceUnit(distance.unit) ?? "")
    }

    private static let mayNotComplete = String(localized: "controls_may_not_complete", bundle: .module)
    private static let penaltyLinePercent = 80
}

/// 조작 장 버튼 하나가 그릴 글자와 아이콘이다.
struct ControlsButtonContent: Equatable {
    let label: String
    let icon: ControlIcon
}

/// 조작 장 자리(화면 위 끝에서 pt)다. 안내가 한 줄이거나 없어도 두 줄 자리를 잡아 버튼이 안 움직인다.
struct ControlsSlots: Equatable {
    /// 첫 안내 잉크의 윗변이다.
    let hintTop: CGFloat
    /// 첫 안내 잉크 윗변에서 둘째 안내 잉크 윗변까지다.
    let hintLineAdvance: CGFloat
    /// 아래 셋은 알약의 윗변이다.
    let firstButtonTop: CGFloat
    let finishButtonTop: CGFloat
    let comboRowTop: CGFloat
    /// 콤보 칸이 스크롤하기 전에도 화면 끝 안에 통째로 들어온다.
    let comboRowFits: Bool
    /// 화면 위 끝부터 스크롤 끝까지다.
    let contentHeight: CGFloat

    // 시계 자리는 앱이 알 수 없어, 안내를 시스템 안전 영역 위 끝부터 쓴다
    init(screen: WatchScreen, sizes: WatchFontSizes) {
        hintTop = screen.safeAreaTop
        let hangulInk = SUITFont.hangulInk
        hintLineAdvance =
            sizes.reading * (hangulInk.aboveBaselineEm + hangulInk.belowBaselineEm) + RunDimensions.lineGap
        firstButtonTop = hintTop + hintLineAdvance * 2 + Self.hintToButtonGap
        finishButtonTop = firstButtonTop + ControlButton.pillHeight + Self.pillGap
        comboRowTop = finishButtonTop + ControlButton.pillHeight + Self.pillGap
        comboRowFits = Self.pillFits(top: comboRowTop, screen: screen)
        contentHeight = comboRowTop + ControlButton.pillHeight + Self.scrollEndMargin
    }

    /// 알약이 화면 아래 끝에서 여백 안쪽에 통째로 들어온다.
    static func pillFits(top: CGFloat, screen: WatchScreen) -> Bool {
        // 알약 양 끝 반원은 어느 애플 화면에서도 모서리 곡선까지 안 가서 아래 끝만 본다
        top + ControlButton.pillHeight <= screen.screenHeight - pillFitEdgeMargin
    }

    // 가장 넓은 칸인 콤보 효과 칸(글자·스위치·여백 116.2)이 들어가는 폭이다
    static let pillWidth: CGFloat = 120

    private static let pillGap: CGFloat = 8
    private static let hintToButtonGap: CGFloat = 5
    private static let pillFitEdgeMargin: CGFloat = 2
    private static let scrollEndMargin: CGFloat = 24
}

/// 콤보 효과 켜기·끄기 칸이다. 글자는 왼쪽, 스위치는 오른쪽 끝에 붙인다.
private struct ComboEffectRow: View {
    let label: String
    let isOn: Bool
    let fontSize: CGFloat

    var body: some View {
        HStack(alignment: .inkCenter, spacing: 0) {
            AlignedTextView(label, size: fontSize, color: RuniverseColors.value)
            Spacer(minLength: Self.labelToSwitchGap)
            ComboSwitchView(isOn: isOn)
        }
        .padding(.leading, Self.labelLeadingPadding)
        .padding(.trailing, Self.switchTrailingPadding)
        .frame(
            width: ControlsSlots.pillWidth,
            height: ControlButton.pillHeight,
            alignment: Alignment(horizontal: .center, vertical: .inkCenter)
        )
        .overlay(Capsule().strokeBorder(Self.outlineColor, lineWidth: Self.outlineWidth))
    }

    private static let outlineColor = Color(white: 0x33 / 255)
    private static let outlineWidth: CGFloat = 1
    private static let labelLeadingPadding: CGFloat = 16
    private static let switchTrailingPadding: CGFloat = 14
    private static let labelToSwitchGap: CGFloat = 6
}

private struct ComboSwitchView: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? LaneColors.color(colorSlot: LaneColors.myColorSlot) : RuniverseColors.buttonBackground)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .padding(Self.thumbInset)
                    .frame(width: Self.height, height: Self.height)
            }
            .frame(width: Self.width, height: Self.height)
    }

    private static let width: CGFloat = 28
    private static let height: CGFloat = 16
    private static let thumbInset: CGFloat = 3
}

#Preview("조작 장 달리는 중") {
    ControlsView(run: RunSamples.party, isPhoneReachable: true, isComboEffectOn: true)
}

#Preview("조작 장 멈춤") {
    ControlsView(run: RunSamples.paused, isPhoneReachable: true, isComboEffectOn: true)
}

#Preview("조작 장 폰 끊김") {
    ControlsView(run: RunSamples.party, isPhoneReachable: false, isComboEffectOn: false)
}
