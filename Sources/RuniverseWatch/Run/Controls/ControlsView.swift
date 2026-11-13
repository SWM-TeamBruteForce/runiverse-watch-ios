import Observation
import SwiftUI

/// 러닝 조작 장이다. 안내 두 줄 아래 일시정지·종료가 있고, 스크롤하면 콤보 효과 칸이 나온다.
struct ControlsView: View {
    let run: RunState
    let isPhoneReachable: Bool
    let commandState: RunCommandState
    let commands: RunCommands
    @Binding var isComboEffectOn: Bool

    @State private var isScrolled = false
    @State private var scrollPosition = ControlsScrollPosition()

    var body: some View {
        let content = ControlsContent(run: run, isPhoneReachable: isPhoneReachable, commandState: commandState)
        GeometryReader { proxy in
            let screen = WatchScreen(proxy)
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let slots = ControlsSlots(screen: screen, sizes: sizes)
            // 내용을 화면 위 끝부터 재서 놓는다 — 스크롤하면 시계 밑까지 올라가 덮개로 흐린다
            ZStack(alignment: .top) {
                ScrollView {
                    ControlsItemsView(
                        content: content,
                        commands: commands,
                        isComboEffectOn: $isComboEffectOn,
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
                    // 스크롤한 거리는 막대만 읽어, 스크롤하는 동안 나머지는 다시 그리지 않는다
                    .onGeometryChange(for: CGFloat.self) {
                        -$0.frame(in: .scrollView).minY
                    } action: {
                        scrollPosition.offset = $0
                    }
                }
                // 시스템 막대는 스크롤할 때만 떠, 늘 보이는 막대를 직접 그린다
                .scrollIndicators(.hidden)
                ClockFadeView(screen: screen)
            }
            .overlay(alignment: .trailing) {
                ControlsScrollBarView(
                    scrollPosition: scrollPosition,
                    contentHeight: slots.contentHeight,
                    viewportHeight: screen.screenHeight
                )
            }
            .ignoresSafeArea()
        }
    }
}

/// 스크롤하는 안내·버튼·콤보 칸이다. 자리는 화면 위 끝부터 잰 높이다.
private struct ControlsItemsView: View {
    let content: ControlsContent
    let commands: RunCommands
    @Binding var isComboEffectOn: Bool
    let isScrolled: Bool
    let screen: WatchScreen
    let sizes: WatchFontSizes
    let slots: ControlsSlots

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.frame(width: screen.screenWidth, height: slots.contentHeight)
            // 남은 거리는 내 거리로 1초마다 바뀌어, 원래 폭 숫자면 가운데 맞춘 줄이 매초 흔들린다
            if let firstHint = content.firstHint {
                AlignedTextView(
                    firstHint,
                    size: sizes.reading,
                    monospacesDigits: true,
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
            ) {
                if content.isPaused { commands.resume() } else { commands.pause() }
            }
            .disabled(content.areButtonsLocked)
            .opacity(content.buttonsAlpha)
            .alignmentGuide(.top) { _ in -slots.firstButtonTop }
            FinishButton(content: content, fontSize: sizes.reading) {
                commands.finish()
            }
            .opacity(content.buttonsAlpha)
            .alignmentGuide(.top) { _ in -slots.finishButtonTop }
            // 화면 끝에 걸쳐 보이면 조잡해, 통째로 안 들어오면 스크롤할 때까지 숨긴다
            let isComboRowShown = slots.comboRowFits || isScrolled
            ComboEffectRow(label: content.comboEffectLabel, isOn: $isComboEffectOn, fontSize: sizes.reading)
                .opacity(isComboRowShown ? 1 : 0)
                .disabled(!isComboRowShown)
                .alignmentGuide(.top) { _ in -slots.comboRowTop }
        }
    }
}

/// 조작 장을 스크롤한 거리다.
@MainActor
@Observable
private final class ControlsScrollPosition {
    var offset: CGFloat = 0
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

/// 조작 장 오른쪽 끝 세로 가운데에 늘 보이는 스크롤 막대다.
private struct ControlsScrollBarView: View {
    let scrollPosition: ControlsScrollPosition
    let contentHeight: CGFloat
    let viewportHeight: CGFloat

    var body: some View {
        let slots = ControlsScrollBarSlots(
            scrollOffset: scrollPosition.offset,
            contentHeight: contentHeight,
            viewportHeight: viewportHeight
        )
        ZStack(alignment: .top) {
            pieceView(slots.topTrack, color: Self.trackColor)
            pieceView(slots.thumb, color: .white)
            pieceView(slots.bottomTrack, color: Self.trackColor)
        }
        .frame(width: ControlsScrollBarSlots.barWidth, height: ControlsScrollBarSlots.spanLength, alignment: .top)
        .padding(.trailing, Self.trailingPadding)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func pieceView(_ piece: ControlsScrollBarPiece, color: Color) -> some View {
        Capsule()
            .fill(color.opacity(piece.alpha))
            .frame(width: piece.width, height: piece.length)
            .offset(y: piece.top)
    }

    private static let trackColor = Color.white.opacity(RunDimensions.inactivePositionAlpha)
    private static let trailingPadding: CGFloat = 2
}

/// 스크롤 막대 세 조각(위 트랙·막대·아래 트랙)의 자리다. 위 트랙 위 끝에서 잰 pt다.
struct ControlsScrollBarSlots: Equatable {
    let topTrack: ControlsScrollBarPiece
    let thumb: ControlsScrollBarPiece
    let bottomTrack: ControlsScrollBarPiece

    // 갤럭시 스크롤바 규칙이다 — 막대 길이는 보이는 몫을 30~70%로 묶고, 위치는 내린 몫이다
    init(scrollOffset: CGFloat, contentHeight: CGFloat, viewportHeight: CGFloat) {
        let scrollableHeight = contentHeight - viewportHeight
        let thumbFraction =
            scrollableHeight > 0
            ? min(max(viewportHeight / contentHeight, Self.minThumbFraction), Self.maxThumbFraction)
            : Self.maxThumbFraction
        let scrolledFraction = scrollableHeight > 0 ? min(max(scrollOffset / scrollableHeight, 0), 1) : 0
        let thumbStart = Self.spanLength * (1 - thumbFraction) * scrolledFraction
        let thumbEnd = thumbStart + Self.spanLength * thumbFraction
        topTrack = Self.piece(from: 0, to: thumbStart)
        thumb = Self.piece(from: thumbStart, to: thumbEnd)
        bottomTrack = Self.piece(from: thumbEnd, to: Self.spanLength)
    }

    // 조각 끝마다 간격 절반을 비우고, 막대 폭보다 짧아지면 점으로 줄며 흐려진다
    private static func piece(from start: CGFloat, to end: CGFloat) -> ControlsScrollBarPiece {
        let span = max(end - start, 0)
        let dotSpan = barWidth + segmentGap
        guard span <= dotSpan else {
            return ControlsScrollBarPiece(
                top: start + segmentGap / 2,
                length: span - segmentGap,
                width: barWidth,
                alpha: 1
            )
        }
        let fraction = span / dotSpan
        let diameter = barWidth * fraction
        return ControlsScrollBarPiece(
            top: (start + end - diameter) / 2,
            length: diameter,
            width: diameter,
            alpha: fraction
        )
    }

    static let barWidth: CGFloat = 5
    static let segmentGap: CGFloat = 3
    // 갤럭시처럼 세 조각이 나눠 쓰는 길이는 50에 조각 사이 간격과 막대 폭을 더한 값이다
    static let spanLength: CGFloat = 50 + barWidth + segmentGap
    private static let minThumbFraction: CGFloat = 0.3
    private static let maxThumbFraction: CGFloat = 0.7
}

/// 스크롤 막대 한 조각이다. 점이면 폭과 길이가 지름이다.
struct ControlsScrollBarPiece: Equatable {
    let top: CGFloat
    let length: CGFloat
    let width: CGFloat
    let alpha: Double
}

/// 종료 버튼이다. 달리는 중엔 길게 눌러야 하고, 멈췄으면 한 번 누르면 끝난다.
private struct FinishButton: View {
    let content: ControlsContent
    let fontSize: CGFloat
    let onFinish: () -> Void

    var body: some View {
        let background = LaneColors.color(colorSlot: LaneColors.myColorSlot)
        if content.finishStage == .hold {
            HoldToFinishButton(
                label: content.finishButton.label,
                icon: content.finishButton.icon,
                fontSize: fontSize,
                background: background,
                isEnabled: !content.areButtonsLocked,
                onFinish: onFinish
            )
        } else {
            ControlButton(
                label: content.finishButton.label,
                icon: content.finishButton.icon,
                fontSize: fontSize,
                width: ControlsSlots.pillWidth,
                background: background,
                action: onFinish
            )
            .disabled(content.areButtonsLocked)
        }
    }
}

/// 길게 눌러 끝내는 종료 버튼이다. 달리는 중에 손가락이 스쳐 기록이 끝나지 않게 한다.
private struct HoldToFinishButton: View {
    let label: String
    let icon: ControlIcon?
    let fontSize: CGFloat
    let background: Color
    let isEnabled: Bool
    let onFinish: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var pressStart: Date?
    @State private var hasFinishedByHolding = false
    @State private var filledFraction: CGFloat = 0
    @State private var isHoldLongerShown = false
    @State private var holdLongerNoticeId = 0

    var body: some View {
        let isPressing = pressStart != nil
        let shownLabel =
            isPressing
            ? ControlsContent.keepPressingLabel : isHoldLongerShown ? ControlsContent.holdLongerLabel : label
        let shownIcon = isHoldLongerShown && !isPressing ? nil : icon
        // 버튼 동작은 손가락을 그 자리에서 뗐을 때만 온다 — 쓸어 넘기면 오지 않아 안내를 안 띄운다
        Button {
            if !hasFinishedByHolding { showHoldLongerNotice() }
            hasFinishedByHolding = false
        } label: {
            ZStack(alignment: .leading) {
                // 바뀌는 글자가 겹쳐 번지며 밀려, 글자는 애니메이션 없이 바꾼다
                ControlButtonLabelView(
                    label: shownLabel,
                    icon: shownIcon,
                    fontSize: fontSize,
                    width: ControlsSlots.pillWidth,
                    background: background
                )
                .transaction { $0.animation = nil }
                // 흰색이 왼쪽부터 차오르고, 찬 부분의 글자는 검게 보인다
                ControlButtonLabelView(
                    label: shownLabel,
                    icon: shownIcon,
                    fontSize: fontSize,
                    width: ControlsSlots.pillWidth,
                    background: .white,
                    foreground: .black
                )
                .transaction { $0.animation = nil }
                .mask(alignment: .leading) {
                    Rectangle().frame(width: ControlsSlots.pillWidth * filledFraction)
                }
                .accessibilityHidden(true)
            }
        }
        .buttonStyle(
            PressReportingButtonStyle { isPressing in
                if isPressing { startPress() } else { endPress() }
            }
        )
        .disabled(!isEnabled)
        // VoiceOver는 계속 누를 수 없어, 길게 누르기 대신 이름 붙은 동작으로 끝낸다
        .accessibilityAction(named: Text(verbatim: label)) {
            if isEnabled { onFinish() }
        }
        // 누른 시간은 채움 애니메이션과 따로 잰다 — 애니메이션이 끝났는지로 재지 않는다
        .task(id: pressStart) {
            guard pressStart != nil else { return }
            try? await Task.sleep(for: .milliseconds(Self.holdToFinishMs))
            guard !Task.isCancelled, pressStart != nil else { return }
            hasFinishedByHolding = true
            pressStart = nil
            filledFraction = 0
            onFinish()
        }
        // 연달아 짧게 누르면 마지막으로 누른 때부터 다시 잰다
        .task(id: holdLongerNoticeId) {
            guard isHoldLongerShown else { return }
            try? await Task.sleep(for: Self.holdLongerNoticeTimeout)
            guard !Task.isCancelled else { return }
            isHoldLongerShown = false
        }
        // 화면이 꺼지거나 누르는 도중 잠기면 손가락이 떨어진 것과 같게 본다
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { endPress() }
        }
        .onChange(of: isEnabled) { _, isEnabled in
            if !isEnabled { endPress() }
        }
    }

    private func showHoldLongerNotice() {
        isHoldLongerShown = true
        holdLongerNoticeId += 1
    }

    // 누르는 동안엔 `계속 누르기`가 먼저라 안내를 지우지 않는다 — 지우면 짧은 탭에서 안내가 안 떴다
    private func startPress() {
        hasFinishedByHolding = false
        pressStart = .now
        withAnimation(.linear(duration: Self.holdSeconds)) { filledFraction = 1 }
    }

    // 찬 만큼 걸린 시간 동안 다시 비운다
    private func endPress() {
        guard let pressStart else { return }
        self.pressStart = nil
        let filledSeconds = min(Date.now.timeIntervalSince(pressStart), Self.holdSeconds)
        withAnimation(.linear(duration: filledSeconds)) { filledFraction = 0 }
    }

    private static let holdToFinishMs = 1200
    private static let holdSeconds = Double(holdToFinishMs) / 1000
    private static let holdLongerNoticeTimeout = Duration.milliseconds(1500)
}

/// 눌림이 바뀔 때마다 알린다. 겉모양은 바꾸지 않는다.
private struct PressReportingButtonStyle: ButtonStyle {
    let onPressingChanged: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in onPressingChanged(isPressed) }
    }
}

/// 조작 장이 그릴 값이다.
struct ControlsContent: Equatable {
    /// 남은 거리나 연결 상태다. 흰 글자로 쓴다.
    let firstHint: String?
    /// 첫 안내에 딸린 주의다. 회색으로 쓴다.
    let secondHint: String?
    /// 멈췄으면 첫 버튼이 일시정지가 아니라 계속 달리기다.
    let isPaused: Bool
    let pauseButton: ControlsButtonContent
    let finishStage: FinishButtonStage
    let finishButton: ControlsButtonContent
    /// 폰이 끊겼거나 보낸 명령·SYNC의 답이나 폰의 종료 확정을 기다린다.
    let areButtonsLocked: Bool
    /// 답을 금방 받는 잠금까지 흐리면 누를 때마다 깜빡여, 오래 걸리는 잠금만 흐린다.
    let buttonsAlpha: Double
    let comboEffectLabel = String(localized: "controls_combo_effect", bundle: .module)

    static let keepPressingLabel = String(localized: "controls_keep_pressing", bundle: .module)
    static let holdLongerLabel = String(localized: "controls_hold_longer", bundle: .module)

    init(run: RunState, isPhoneReachable: Bool, commandState: RunCommandState) {
        isPaused = run.status == .paused
        pauseButton =
            isPaused
            ? ControlsButtonContent(label: String(localized: "controls_resume", bundle: .module), icon: .play)
            : ControlsButtonContent(label: String(localized: "controls_pause", bundle: .module), icon: .pause)

        // 폰이 서버 답을 기다리는 동안엔 폰도 명령을 무시한다
        let isPhoneFinishing = run.finish?.stage == .finishing
        if commandState.isFinishPending, commandState.isCommandOverdue {
            finishStage = .checking
        } else if commandState.isFinishPending || isPhoneFinishing {
            finishStage = .finishing
        } else if isPaused {
            finishStage = .tap
        } else {
            finishStage = .hold
        }
        finishButton = Self.finishButton(finishStage)
        areButtonsLocked = !isPhoneReachable || commandState.isLocked || isPhoneFinishing
        let areButtonsDimmed =
            !isPhoneReachable || commandState.isFinishPending || commandState.isCommandOverdue || isPhoneFinishing
        buttonsAlpha = areButtonsDimmed ? RunDimensions.staleContentAlpha : 1

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
            // 받은 목표가 커도 곱셈이 넘쳐 죽지 않게 100으로 먼저 나눈다
            let penaltyLineMeters =
                targetDistanceMeters / 100 * Self.penaltyLinePercent
                + targetDistanceMeters % 100 * Self.penaltyLinePercent / 100
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

    private static func finishButton(_ stage: FinishButtonStage) -> ControlsButtonContent {
        switch stage {
        case .hold:
            ControlsButtonContent(label: String(localized: "controls_hold_to_finish", bundle: .module), icon: .stop)
        case .tap:
            ControlsButtonContent(label: String(localized: "controls_finish", bundle: .module), icon: .stop)
        case .finishing:
            ControlsButtonContent(label: String(localized: "controls_finishing", bundle: .module), icon: nil)
        case .checking:
            ControlsButtonContent(label: String(localized: "controls_finish_checking", bundle: .module), icon: nil)
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
    /// 종료를 보낸 뒤처럼 글자만 쓰는 상태가 있다.
    let icon: ControlIcon?
}

/// 종료 버튼이 어떻게 눌리는지다.
enum FinishButtonStage: Equatable {
    /// 달리는 중이라 길게 눌러야 끝난다.
    case hold
    /// 멈췄으면 이미 한 번 멈춘 뜻이라 한 번에 끝낸다.
    case tap
    /// 종료를 보냈거나 폰이 서버 답을 기다린다.
    case finishing
    /// 종료를 보낸 지 3초가 넘도록 답이 없다.
    case checking
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
    @Binding var isOn: Bool
    let fontSize: CGFloat

    var body: some View {
        Toggle(isOn: $isOn) {
            AlignedTextView(label, size: fontSize, color: RuniverseColors.value)
        }
        .toggleStyle(ComboEffectToggleStyle())
    }
}

/// 칸 어디를 눌러도 켜고 끈다.
private struct ComboEffectToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .inkCenter, spacing: 0) {
                configuration.label
                Spacer(minLength: Self.labelToSwitchGap)
                ComboSwitchView(isOn: configuration.isOn)
            }
            .padding(.leading, Self.labelLeadingPadding)
            .padding(.trailing, Self.switchTrailingPadding)
            .frame(
                width: ControlsSlots.pillWidth,
                height: ControlButton.pillHeight,
                alignment: Alignment(horizontal: .center, vertical: .inkCenter)
            )
            .overlay(Capsule().strokeBorder(Self.outlineColor, lineWidth: Self.outlineWidth))
            .contentShape(Capsule())
        }
        .buttonStyle(UndimmedButtonStyle())
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
    ControlsView(
        run: RunSamples.party,
        isPhoneReachable: true,
        commandState: RunCommandState(),
        commands: RunCommands(pause: {}, resume: {}, finish: {}),
        isComboEffectOn: .constant(true)
    )
}

#Preview("조작 장 멈춤") {
    ControlsView(
        run: RunSamples.paused,
        isPhoneReachable: true,
        commandState: RunCommandState(),
        commands: RunCommands(pause: {}, resume: {}, finish: {}),
        isComboEffectOn: .constant(true)
    )
}

#Preview("조작 장 폰 끊김") {
    ControlsView(
        run: RunSamples.party,
        isPhoneReachable: false,
        commandState: RunCommandState(),
        commands: RunCommands(pause: {}, resume: {}, finish: {}),
        isComboEffectOn: .constant(false)
    )
}

#Preview("조작 장 종료 중") {
    ControlsView(
        run: RunSamples.paused,
        isPhoneReachable: true,
        commandState: RunCommandState(isLocked: true, isFinishPending: true),
        commands: RunCommands(pause: {}, resume: {}, finish: {}),
        isComboEffectOn: .constant(true)
    )
}
