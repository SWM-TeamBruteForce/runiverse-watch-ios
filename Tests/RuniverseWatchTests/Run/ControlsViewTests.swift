import CoreGraphics
import Testing

@testable import RuniverseWatch

struct ControlsViewTests {

    // 조작 장에서 잰 시뮬레이터 화면이다 — 울트라 3·2, 46·45·42·41·40mm
    private static let appleScreens = [
        WatchScreen(screenWidth: 211, screenHeight: 257, safeAreaTop: 56.5, safeAreaBottom: 217),
        WatchScreen(screenWidth: 205, screenHeight: 251, safeAreaTop: 55, safeAreaBottom: 212),
        WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212),
        WatchScreen(screenWidth: 198, screenHeight: 242, safeAreaTop: 51, safeAreaBottom: 215),
        WatchScreen(screenWidth: 187, screenHeight: 223, safeAreaTop: 48, safeAreaBottom: 192),
        WatchScreen(screenWidth: 176, screenHeight: 215, safeAreaTop: 46, safeAreaBottom: 189),
        WatchScreen(screenWidth: 162, screenHeight: 197, safeAreaTop: 40, safeAreaBottom: 171),
    ]

    @Test
    func `달리는 중엔 일시정지와 길게 눌러야 끝나는 종료를 쓴다`() {
        // when
        let content = content(RunSamples.party)

        // then
        #expect(content.pauseButton == ControlsButtonContent(label: "일시정지", icon: .pause))
        #expect(content.finishStage == .hold)
        #expect(content.finishButton == ControlsButtonContent(label: "길게 눌러 종료", icon: .stop))
    }

    @Test
    func `멈췄으면 계속 달리기와 한 번에 끝나는 종료를 쓴다`() {
        // when
        let content = content(RunSamples.paused)

        // then
        #expect(content.isPaused)
        #expect(content.pauseButton == ControlsButtonContent(label: "계속 달리기", icon: .play))
        #expect(content.finishStage == .tap)
        #expect(content.finishButton == ControlsButtonContent(label: "종료", icon: .stop))
    }

    @Test
    func `종료를 보내면 종료 중이고 3초 넘게 답이 없으면 종료 확인 중이다`() {
        // given
        let pending = RunCommandState(isLocked: true, isFinishPending: true)
        let overdue = RunCommandState(isLocked: true, isFinishPending: true, isCommandOverdue: true)

        // when
        let finishing = content(RunSamples.party, commandState: pending)
        let checking = content(RunSamples.party, commandState: overdue)

        // then
        #expect(finishing.finishStage == .finishing)
        #expect(finishing.finishButton == ControlsButtonContent(label: "종료 중", icon: nil))
        #expect(checking.finishStage == .checking)
        #expect(checking.finishButton == ControlsButtonContent(label: "종료 확인 중", icon: nil))
    }

    @Test
    func `멈춘 상태에서 종료를 보내도 종료 중으로 바뀐다`() {
        // when
        let content = content(RunSamples.paused, commandState: RunCommandState(isLocked: true, isFinishPending: true))

        // then
        #expect(content.finishStage == .finishing)
    }

    @Test
    func `일시정지 답이 늦어도 종료 문구를 띄우지 않는다`() {
        // when
        let content = content(RunSamples.party, commandState: RunCommandState(isLocked: true, isCommandOverdue: true))

        // then
        #expect(content.finishStage == .hold)
    }

    @Test
    func `폰이 서버 답을 기다리면 폰에서 누른 종료여도 종료 중으로 잠그고 흐린다`() {
        // given
        let phoneFinishing = FinishProgress(stage: .finishing, remainingMeters: nil)

        // when
        let content = content(run(distanceMeters: 3421, finish: phoneFinishing))

        // then
        #expect(content.finishStage == .finishing)
        #expect(content.areButtonsLocked)
        #expect(content.buttonsAlpha == 0.4)
    }

    @Test
    func `서버 보류 중엔 다시 끝낼 수 있게 버튼이 돌아온다`() {
        // when
        let content = content(
            run(status: .paused, distanceMeters: 5000, finish: FinishProgress(stage: .goalPending, remainingMeters: 40))
        )

        // then
        #expect(content.finishStage == .tap)
        #expect(!content.areButtonsLocked)
    }

    @Test
    func `폰이 끊기거나 명령 답을 기다리면 잠근다`() {
        // when & then
        #expect(content(RunSamples.party, isPhoneReachable: false).areButtonsLocked)
        #expect(content(RunSamples.party, commandState: RunCommandState(isLocked: true)).areButtonsLocked)
        #expect(!content(RunSamples.party).areButtonsLocked)
    }

    @Test
    func `일시정지 답을 기다리는 동안은 잠그되 흐리지 않고, 3초가 넘으면 흐린다`() {
        // when
        let waiting = content(RunSamples.party, commandState: RunCommandState(isLocked: true))
        let overdue = content(RunSamples.party, commandState: RunCommandState(isLocked: true, isCommandOverdue: true))

        // then
        #expect(waiting.buttonsAlpha == 1)
        #expect(overdue.buttonsAlpha == 0.4)
    }

    @Test
    func `종료를 보내면 3초가 지나기 전에도 바로 흐린다`() {
        // when
        let content = content(RunSamples.party, commandState: RunCommandState(isLocked: true, isFinishPending: true))

        // then
        #expect(content.buttonsAlpha == 0.4)
    }

    @Test
    func `폰이 끊기면 버튼을 흐린다`() {
        // when & then
        #expect(content(RunSamples.party, isPhoneReachable: false).buttonsAlpha == 0.4)
    }

    @Test
    func `제재 방 80퍼센트 전에는 80퍼센트까지 남은 거리와 매칭 제한을 알린다`() {
        // given -> 목표 5000m의 80%는 4000m라 579m 남았다
        let running = run(distanceMeters: 3421)
        let paused = run(status: .paused, distanceMeters: 3421)

        // when & then
        #expect(hints(running) == Hints(first: "80%까지 약 579m", second: "못 채우면 20분 매칭 제한"))
        #expect(hints(paused) == Hints(first: "80%까지 약 579m", second: "끝내면 20분 매칭 제한"))
    }

    @Test
    func `80퍼센트 지점에 닿으면 목표까지 남은 거리로 바뀐다`() {
        // when & then -> 목표 5000m의 80%인 4000m가 경계다
        #expect(hints(run(distanceMeters: 3999)) == Hints(first: "80%까지 약 1m", second: "못 채우면 20분 매칭 제한"))
        #expect(hints(run(distanceMeters: 4000)) == Hints(first: "목표까지 약 1.0km", second: nil))
    }

    @Test
    func `목표 거리가 Int의 가장 큰 값이어도 80퍼센트 선을 재다 죽지 않는다`() {
        // given
        let run = RunState(
            runningRoomId: nil,
            type: .match,
            status: .running,
            targetDistanceMeters: Int.max,
            isServerConnected: true,
            isPenaltyApplicable: true,
            me: RunSamples.party.me,
            players: RunSamples.party.players,
            finish: nil,
            result: nil
        )

        // when
        let hints = hints(run)

        // then
        #expect(hints.first?.hasPrefix("80%까지 약 ") == true)
    }

    @Test
    func `80퍼센트를 넘으면 목표까지 남은 거리로 바뀌고 멈췄을 때만 미완주를 알린다`() {
        // given
        let running = run(distanceMeters: 4200)
        let paused = run(status: .paused, distanceMeters: 4200)

        // when & then
        #expect(hints(running) == Hints(first: "목표까지 약 800m", second: nil))
        #expect(hints(paused) == Hints(first: "목표까지 약 800m", second: "끝내면 미완주 가능"))
    }

    @Test
    func `제재 없는 방은 80퍼센트 전에도 목표까지 남은 거리를 올려서 알린다`() {
        // given -> 1579m 남아 1.6km다
        let run = run(distanceMeters: 3421, isPenaltyApplicable: false)

        // when & then
        #expect(hints(run) == Hints(first: "목표까지 약 1.6km", second: nil))
    }

    @Test
    func `화면 거리가 목표에 닿으면 확인 중으로 두고 달리는 중에만 계속 달리기를 권한다`() {
        // given
        let running = run(distanceMeters: 5000)
        let paused = run(status: .paused, distanceMeters: 5000)

        // when & then
        #expect(hints(running) == Hints(first: "거리 확인 중", second: "모자라면 계속 달리기"))
        #expect(hints(paused) == Hints(first: "거리 확인 중", second: nil))
    }

    @Test
    func `서버가 남은 거리를 답하면 화면 거리보다 먼저 쓴다`() {
        // given -> 화면 거리는 목표에 닿았지만 서버는 40m 모자라다고 답했다
        let pending = FinishProgress(stage: .goalPending, remainingMeters: 40)
        let running = run(distanceMeters: 5000, finish: pending)
        let paused = run(status: .paused, distanceMeters: 5000, finish: pending)

        // when & then
        #expect(hints(running) == Hints(first: "목표까지 약 40m", second: nil))
        #expect(hints(paused) == Hints(first: "목표까지 약 40m", second: "끝내면 미완주 가능"))
    }

    @Test
    func `폰 끊김 안내가 서버 끊김보다 먼저다`() {
        // when & then
        #expect(
            hints(RunSamples.serverLost, isPhoneReachable: false)
                == Hints(first: "폰 연결 확인 중", second: "연결 후 조작 가능")
        )
        #expect(hints(RunSamples.serverLost) == Hints(first: "서버 연결 확인 중", second: "러닝 기록 중"))
    }

    @Test
    func `혼자 달리면 서버가 끊겨도 서버 안내를 띄우지 않고, 목표 없는 솔로는 안내가 없다`() {
        // given
        let soloServerLost = RunState(
            runningRoomId: nil,
            type: .solo,
            status: .running,
            targetDistanceMeters: nil,
            isServerConnected: false,
            isPenaltyApplicable: false,
            me: RunSamples.solo.me,
            players: [],
            finish: nil,
            result: nil
        )

        // when & then
        #expect(hints(soloServerLost) == Hints(first: nil, second: nil))
        #expect(hints(RunSamples.solo) == Hints(first: nil, second: nil))
    }

    @Test
    func `안내는 안전 영역 위 끝에서 시작하고 첫 버튼은 안내 두 줄 끝에서 5 아래다`() {
        // given -> 46mm 시뮬레이터에서 잰 화면이다
        let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)

        // when
        let slots = ControlsSlots(screen: screen, sizes: WatchFontSizes(screenWidth: screen.screenWidth))

        // then -> 14pt 한글 잉크 12.488과 줄 간격 7이 두 줄이고, 버튼은 높이 48·간격 8로 이어진다
        #expect(slots.hintTop == 53)
        #expect(abs(slots.firstButtonTop - 96.976) < 0.001)
        #expect(abs(slots.finishButtonTop - 152.976) < 0.001)
        #expect(abs(slots.comboRowTop - 208.976) < 0.001)
    }

    @Test(arguments: appleScreens)
    func `종료 버튼은 스크롤하기 전에도 화면 안에 통째로 들어온다`(screen: WatchScreen) {
        // given
        let slots = ControlsSlots(screen: screen, sizes: WatchFontSizes(screenWidth: screen.screenWidth))

        // when & then
        #expect(ControlsSlots.pillFits(top: slots.finishButtonTop, screen: screen))
    }

    @Test(arguments: appleScreens)
    func `콤보 칸은 안전 영역부터 안내를 쓰면 스크롤해야 보인다`(screen: WatchScreen) {
        // when
        let slots = ControlsSlots(screen: screen, sizes: WatchFontSizes(screenWidth: screen.screenWidth))

        // then
        #expect(!slots.comboRowFits)
    }

    @Test
    func `알약은 화면 아래 끝 여백까지 들어오면 들어온 것으로 본다`() {
        // given -> 46mm는 높이 248에서 여백 2를 빼면 알약 아래 끝이 246까지다
        let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)

        // when & then
        #expect(ControlsSlots.pillFits(top: 198, screen: screen))
        #expect(!ControlsSlots.pillFits(top: 198.5, screen: screen))
    }

    @Test(arguments: appleScreens)
    func `알약 양 끝 반원은 화면 모서리 곡선이 시작하는 곳보다 안쪽에 있다`(screen: WatchScreen) {
        // when -> 반원 중심이 화면 가운데에서 떨어진 거리다
        let capCenterFromScreenCenter = ControlsSlots.pillWidth / 2 - ControlButton.pillHeight / 2

        // then -> 그래서 알약은 아래 끝만 재면 된다
        #expect(capCenterFromScreenCenter <= screen.screenWidth / 2 - screen.cornerRadius)
    }

    @Test
    func `나올 수 있는 모든 안내가 가장 좁은 화면에서도 한 줄에 들어간다`() {
        // given -> 40mm다. 남은 거리는 1m부터 마라톤 거리까지 본다
        let screen = WatchScreen(screenWidth: 162, screenHeight: 197, safeAreaTop: 40, safeAreaBottom: 171)
        let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
        let slots = ControlsSlots(screen: screen, sizes: sizes)
        let remainingTexts = Set(
            (1...42_195).map {
                let distance = RunFormat.formatRemainingDistance($0)
                return distance.value + (RunTexts.distanceUnit(distance.unit) ?? "")
            }
        )
        let firstHints =
            remainingTexts.flatMap {
                [
                    String(localized: "controls_to_penalty_line \($0)", bundle: .module),
                    String(localized: "controls_to_goal \($0)", bundle: .module),
                ]
            }
            + ["run_phone_checking", "run_server_checking", "controls_distance_checking"].map {
                String(localized: String.LocalizationValue($0), bundle: .module)
            }
        let secondHints = [
            "controls_after_reconnect", "controls_run_recording", "controls_keep_running_if_short",
            "controls_penalty_if_short", "controls_penalty_if_finished", "controls_may_not_complete",
        ]
        .map { String(localized: String.LocalizationValue($0), bundle: .module) }

        // when -> 첫 안내는 같은 폭 숫자로 그린다
        let widestFirst =
            firstHints.map {
                SUITFont.width(of: $0, size: sizes.reading, weight: .semiBold, monospacesDigits: true)
            }
            .max() ?? 0
        let widestSecond =
            secondHints.map { SUITFont.width(of: $0, size: sizes.reading, weight: .semiBold) }.max() ?? 0

        // then
        let margin = RunDimensions.textEdgeMargin
        #expect(widestFirst <= screen.usableWidth(atY: slots.hintTop, margin: margin))
        #expect(widestSecond <= screen.usableWidth(atY: slots.hintTop + slots.hintLineAdvance, margin: margin))
    }

    @Test
    func `스크롤 전엔 막대가 위 끝에 붙고 위 트랙은 비어 있다`() {
        // when -> 보이는 몫이 절반이다
        let slots = ControlsScrollBarSlots(scrollOffset: 0, contentHeight: 400, viewportHeight: 200)

        // then -> 전체 58을 반씩 나누고, 조각 끝마다 간격 절반 1.5를 비운다
        #expect(slots.topTrack == ControlsScrollBarPiece(top: 0, length: 0, width: 0, alpha: 0))
        #expect(slots.thumb == ControlsScrollBarPiece(top: 1.5, length: 26, width: 5, alpha: 1))
        #expect(slots.bottomTrack == ControlsScrollBarPiece(top: 30.5, length: 26, width: 5, alpha: 1))
    }

    @Test
    func `끝까지 내리면 막대가 아래 끝에 붙는다`() {
        // when
        let slots = ControlsScrollBarSlots(scrollOffset: 200, contentHeight: 400, viewportHeight: 200)

        // then
        #expect(slots.topTrack == ControlsScrollBarPiece(top: 1.5, length: 26, width: 5, alpha: 1))
        #expect(slots.thumb == ControlsScrollBarPiece(top: 30.5, length: 26, width: 5, alpha: 1))
        #expect(slots.bottomTrack == ControlsScrollBarPiece(top: 58, length: 0, width: 0, alpha: 0))
    }

    @Test
    func `당겨 넘쳐도 막대는 양 끝에서 멈춘다`() {
        // given
        let atTop = ControlsScrollBarSlots(scrollOffset: 0, contentHeight: 400, viewportHeight: 200)
        let atBottom = ControlsScrollBarSlots(scrollOffset: 200, contentHeight: 400, viewportHeight: 200)

        // when -> 튕기는 동안 내린 거리는 0보다 작거나 끝보다 크다
        let pulledDown = ControlsScrollBarSlots(scrollOffset: -40, contentHeight: 400, viewportHeight: 200)
        let pulledUp = ControlsScrollBarSlots(scrollOffset: 260, contentHeight: 400, viewportHeight: 200)

        // then
        #expect(pulledDown == atTop)
        #expect(pulledUp == atBottom)
    }

    @Test
    func `막대 길이는 보이는 몫이되 30에서 70퍼센트로 묶는다`() {
        // when
        let longContent = ControlsScrollBarSlots(scrollOffset: 0, contentHeight: 1000, viewportHeight: 200)
        let shortContent = ControlsScrollBarSlots(scrollOffset: 0, contentHeight: 210, viewportHeight: 200)

        // then -> 전체 58의 30%·70%에서 간격 3을 뺀다
        #expect(abs(longContent.thumb.length - 14.4) < 0.001)
        #expect(abs(shortContent.thumb.length - 37.6) < 0.001)
    }

    @Test
    func `내릴 게 없으면 가장 긴 막대를 위 끝에 붙인다`() {
        // when
        let slots = ControlsScrollBarSlots(scrollOffset: 0, contentHeight: 200, viewportHeight: 215)

        // then
        #expect(slots.thumb.top == 1.5)
        #expect(abs(slots.thumb.length - 37.6) < 0.001)
    }

    @Test
    func `막대 폭보다 짧아진 조각은 점으로 줄며 흐려진다`() {
        // when -> 막대가 70%에 묶여 10을 내리면 위 트랙이 3 남는다
        let slots = ControlsScrollBarSlots(scrollOffset: 10, contentHeight: 258, viewportHeight: 200)

        // then -> 막대 폭과 간격을 더한 8 중 3이라 지름·진하기가 0.375배다
        #expect(abs(slots.topTrack.width - 1.875) < 0.001)
        #expect(abs(slots.topTrack.length - 1.875) < 0.001)
        #expect(abs(slots.topTrack.alpha - 0.375) < 0.001)
        #expect(abs(slots.topTrack.top - 0.5625) < 0.001)
    }

    private func content(
        _ run: RunState,
        isPhoneReachable: Bool = true,
        commandState: RunCommandState = RunCommandState()
    ) -> ControlsContent {
        ControlsContent(run: run, isPhoneReachable: isPhoneReachable, commandState: commandState)
    }

    private func hints(_ run: RunState, isPhoneReachable: Bool = true) -> Hints {
        let content = content(run, isPhoneReachable: isPhoneReachable)
        return Hints(first: content.firstHint, second: content.secondHint)
    }

    private func run(
        status: RunStatus = .running,
        distanceMeters: Int,
        isPenaltyApplicable: Bool = true,
        finish: FinishProgress? = nil
    ) -> RunState {
        let sample = RunSamples.party
        return RunState(
            runningRoomId: sample.runningRoomId,
            type: sample.type,
            status: status,
            targetDistanceMeters: sample.targetDistanceMeters,
            isServerConnected: sample.isServerConnected,
            isPenaltyApplicable: isPenaltyApplicable,
            me: MyRecord(
                distanceMeters: distanceMeters,
                elapsedSeconds: sample.me.elapsedSeconds,
                currentPaceSecondsPerKm: sample.me.currentPaceSecondsPerKm,
                caloriesKcal: sample.me.caloriesKcal,
                cadenceSpm: sample.me.cadenceSpm
            ),
            players: sample.players,
            finish: finish,
            result: nil
        )
    }

    private struct Hints: Equatable {
        let first: String?
        let second: String?
    }
}
