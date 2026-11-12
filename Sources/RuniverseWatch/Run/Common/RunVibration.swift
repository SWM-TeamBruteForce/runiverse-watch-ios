import WatchKit

/// 울릴 진동이다. watchOS는 정해진 진동만 있어 갤럭시처럼 길이로 못 가르고 종류로 가른다.
struct RunVibration: Equatable {
    let haptic: WKHapticType
    /// 같은 진동을 `RunVibration.pulseInterval` 간격으로 이만큼 울린다.
    let pulseCount: Int
    /// 급할수록 크다 — 울리는 중인 것보다 급하지 않은 진동은 버린다.
    let priority: Int
    /// 첫 울림부터 다 울릴 때까지다.
    let duration: Duration

    static let goalPending = single(.notification, duration: goalPendingDuration, priority: goalPendingPriority)

    static func combo(_ kind: ComboKind, headcount: Int) -> RunVibration {
        switch kind {
        case .tick:
            single(comboHaptic, duration: tickDuration, priority: tickPriority)
        case .break:
            single(.directionDown, duration: breakDuration, priority: breakPriority)
        case .milestone:
            milestone(pulseCount: milestonePulseCount + (headcount >= extraPulseFromHeadcount ? 1 : 0))
        }
    }

    /// 나와 콤보 중인 사람 수에 나를 더한다. 상태가 아직 안 와도 지금 순간의 그 사람은 센다.
    static func comboHeadcount(players: [Player], comboUserId: String) -> Int {
        players.count { $0.comboCount > 0 || $0.userId == comboUserId } + 1
    }

    // 갤럭시 박자(울림 0.09초 + 쉼 0.12초)로 되풀이한다
    static let pulseInterval = Duration.milliseconds(210)

    private static func single(_ haptic: WKHapticType, duration: Duration, priority: Int) -> RunVibration {
        RunVibration(haptic: haptic, pulseCount: 1, priority: priority, duration: duration)
    }

    private static func milestone(pulseCount: Int) -> RunVibration {
        RunVibration(
            haptic: comboHaptic,
            pulseCount: pulseCount,
            priority: milestonePriority,
            duration: pulseInterval * (pulseCount - 1) + tickDuration
        )
    }

    // 갤럭시처럼 큰 순간은 1 오름 진동을 되풀이한다
    private static let comboHaptic = WKHapticType.directionUp

    // 보류는 할 일이 생긴 신호라 가장 급하고, 끊김은 다시 붙으라는 신호라 칭찬(눈금)보다 급하다
    private static let tickPriority = 0
    private static let milestonePriority = 1
    private static let breakPriority = 2
    private static let goalPendingPriority = 3

    // watchOS는 진동 길이를 알려 주지 않아 갤럭시 길이로 어림한 추정값이다
    private static let tickDuration = Duration.milliseconds(90)
    private static let breakDuration = Duration.milliseconds(180)
    private static let goalPendingDuration = Duration.milliseconds(300)

    // 폰과 같다 — 두 번 울리고 넷부터는 한 번 더 울린다
    private static let milestonePulseCount = 2
    private static let extraPulseFromHeadcount = 4
}

/// 진동이 겹치지 않게 거른다 — 울리는 중인 것보다 급하지 않으면 버린다.
@MainActor
final class RunVibrator {
    private let play: @MainActor (WKHapticType) -> Void
    private let now: () -> ContinuousClock.Instant
    private let schedule: PhoneSchedule

    private var playingUntil: ContinuousClock.Instant?
    private var playingPriority = 0
    private var pulseTimers: [PhoneTimer] = []

    /// `now`·`schedule`은 테스트가 시간을 직접 흘리려고 바꿔 끼운다.
    init(
        play: @escaping @MainActor (WKHapticType) -> Void,
        now: @escaping () -> ContinuousClock.Instant = { ContinuousClock.now },
        schedule: @escaping PhoneSchedule = PhoneLink.sleepThenRun
    ) {
        self.play = play
        self.now = now
        self.schedule = schedule
    }

    func onCombo(_ combo: WatchComboTriggered, linkState: PhoneLinkState) {
        // 러닝을 접은 뒤 늦게 온 콤보는 울릴 일이 아니다
        guard linkState.isRunActive, let players = linkState.phoneState?.run?.players else { return }
        let headcount = RunVibration.comboHeadcount(players: players, comboUserId: combo.userId)
        vibrate(.combo(combo.kind, headcount: headcount))
    }

    func vibrate(_ vibration: RunVibration) {
        let current = now()
        if let playingUntil, current < playingUntil, vibration.priority <= playingPriority { return }
        playingUntil = current + vibration.duration
        playingPriority = vibration.priority
        // 더 급한 진동이 끼면 남은 되풀이를 멈춰 둘이 섞이지 않게 한다
        for timer in pulseTimers { timer.cancel() }
        pulseTimers = (1..<vibration.pulseCount).map { pulse in
            schedule(RunVibration.pulseInterval * pulse) { [weak self] in self?.play(vibration.haptic) }
        }
        play(vibration.haptic)
    }
}
