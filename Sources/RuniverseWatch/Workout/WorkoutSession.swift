import Foundation
import HealthKit
import Observation

/// 러닝 동안 세션을 켜 두고 심박을 받는다. 러닝이 끝났거나 폰이 안 돌아오면 끝낸다.
@MainActor
@Observable
final class WorkoutSession {
    /// 세션이 없거나 못 재면 nil이다.
    private(set) var heartRateBpm: Int?

    @ObservationIgnored private let phoneLink: PhoneLink
    @ObservationIgnored private let tracker: WorkoutTracker
    @ObservationIgnored private let now: () -> ContinuousClock.Instant
    @ObservationIgnored private let schedule: PhoneSchedule

    @ObservationIgnored private var trackerState = TrackerState.idle
    // 다른 앱 운동을 덮어쓰지 않게, 시작에 실패했거나 밀린 세션은 이번 러닝엔 다시 켜지 않는다
    @ObservationIgnored private var isTrackerBlocked = false
    @ObservationIgnored private var launchConfiguration: HKWorkoutConfiguration?
    @ObservationIgnored private var isWatchingPhone = false
    @ObservationIgnored private var checkTimer: PhoneTimer?
    @ObservationIgnored private var heardState: PhoneState?
    @ObservationIgnored private var heardAt: ContinuousClock.Instant
    @ObservationIgnored private var probedAt: ContinuousClock.Instant
    @ObservationIgnored private var unansweredSince: ContinuousClock.Instant?

    /// `now`·`schedule`은 테스트가 시간을 직접 흘리려고 바꿔 끼운다.
    init(
        phoneLink: PhoneLink,
        tracker: WorkoutTracker,
        now: @escaping () -> ContinuousClock.Instant = { ContinuousClock.now },
        schedule: @escaping PhoneSchedule = PhoneLink.sleepThenRun
    ) {
        self.phoneLink = phoneLink
        self.tracker = tracker
        self.now = now
        self.schedule = schedule
        heardAt = now()
        probedAt = heardAt
        tracker.onHeartRate = { [weak self] in self?.onHeartRate($0) }
        tracker.onEndedBySystem = { [weak self] in self?.onEndedBySystem() }
        phoneLink.onStateChanged = { [weak self] in self?.onPhoneLinkChanged($0) }
    }

    /// 화면이 처음 뜰 때 묻는다. 이미 답한 권한이면 창을 띄우지 않는다.
    func requestAuthorization() {
        tracker.requestAuthorization {}
    }

    /// 폰이 러닝을 시작하며 워치 앱을 켰다. 폰 답을 기다리지 않고 바로 시작한다.
    func onLaunchedByPhone(_ configuration: HKWorkoutConfiguration) {
        // 폰이 SYNC를 거절해 이 러닝을 받을 수 없다
        guard !phoneLink.state.isUpdateRequired else { return }
        launchConfiguration = configuration
        if isWatchingPhone {
            // 폰이 다시 켰으면 밀렸던 세션도 다시 켜 본다
            isTrackerBlocked = false
        } else {
            beginWatching()
        }
        updateTracker()
    }

    /// 운동 세션 중에 앱이 죽었다 다시 떴다.
    func onRecoveryRequested() {
        guard trackerState == .idle else { return }
        trackerState = .changing
        tracker.recover { [weak self] isRecovered in
            guard let self else { return }
            trackerState = isRecovered ? .running : .idle
            // 되찾는 사이 폰이 러닝이 없다고 했으면 지켜보지 않아 바로 끝난다
            if isRecovered, !isWatchingPhone, !Self.isRunOver(phoneLink.state) { beginWatching() }
            updateTracker()
        }
    }

    private func onPhoneLinkChanged(_ linkState: PhoneLinkState) {
        // SYNC 중엔 앞 상태라 판단을 SYNCED까지 미룬다
        guard !linkState.isSyncing else { return }
        if linkState.isUpdateRequired {
            if isWatchingPhone { stopWatching() }
            return
        }
        // 폰 상태가 그대로인 변화는 넘긴다 — 폰이 켠 직후엔 지난 러닝 상태가 남아 있다
        guard linkState.phoneState != heardState else { return }
        heardState = linkState.phoneState
        heardAt = now()
        unansweredSince = nil
        if linkState.isRunActive {
            if !isWatchingPhone {
                beginWatching()
                updateTracker()
            }
        } else if linkState.phoneState != nil, isWatchingPhone {
            stopWatching()
        }
    }

    private func beginWatching() {
        isWatchingPhone = true
        isTrackerBlocked = false
        heardState = phoneLink.state.phoneState
        heardAt = now()
        probedAt = heardAt
        unansweredSince = nil
        scheduleCheck()
    }

    private func stopWatching() {
        isWatchingPhone = false
        launchConfiguration = nil
        checkTimer?.cancel()
        updateTracker()
    }

    // 시작·끝내기가 끝날 때마다 다시 불러, 그사이 바뀐 러닝에 맞춘다
    private func updateTracker() {
        switch trackerState {
        case .changing:
            return
        case .idle:
            if isWatchingPhone, !isTrackerBlocked { startTracker() }
        case .running:
            if !isWatchingPhone { endTracker() }
        }
    }

    private func startTracker() {
        trackerState = .changing
        let configuration = launchConfiguration ?? Self.runningConfiguration
        // 대기 화면을 거치지 않은 첫 러닝이면 여기서 묻는다
        tracker.requestAuthorization { [weak self] in
            guard let self else { return }
            // 묻는 사이 러닝이 끝났으면 끝난 러닝에 세션을 시작하지 않는다
            guard isWatchingPhone else {
                trackerState = .idle
                return
            }
            tracker.start(configuration: configuration) { [weak self] isStarted in
                guard let self else { return }
                trackerState = isStarted ? .running : .idle
                if !isStarted { isTrackerBlocked = true }
                updateTracker()
            }
        }
    }

    private func endTracker() {
        trackerState = .changing
        heartRateBpm = nil
        tracker.end { [weak self] in
            guard let self else { return }
            trackerState = .idle
            updateTracker()
        }
    }

    private func onEndedBySystem() {
        guard trackerState == .running else { return }
        trackerState = .idle
        heartRateBpm = nil
        isTrackerBlocked = true
    }

    private func onHeartRate(_ heartRateBpm: Int?) {
        // 끝내는 중에 늦게 온 심박은 버린다
        guard trackerState == .running else { return }
        self.heartRateBpm = heartRateBpm
        checkPhone()
    }

    private func scheduleCheck() {
        checkTimer?.cancel()
        checkTimer = schedule(Self.checkInterval) { [weak self] in
            guard let self else { return }
            checkPhone()
            if isWatchingPhone { scheduleCheck() }
        }
    }

    // 잠든 사이 타이머가 밀릴 수 있어, 잠든 시간도 세는 시계로 재고 심박이 올 때도 확인한다
    // 화면이 꺼진 동안 폰이 조용한 건 정상이라, 물어본 뒤에도 답이 없는 시간만 센다
    private func checkPhone() {
        guard isWatchingPhone else { return }
        let current = now()
        if current - heardAt < Self.probeDelay { return }
        let since = unansweredSince ?? current
        unansweredSince = since
        if current - probedAt < Self.probeDelay { return }
        // 오래 잠든 사이 폰이 돌아왔을 수 있어, 10분이 지난 뒤에 보낸 물음에도 답이 없어야 끝낸다
        if probedAt - since >= Self.giveUpTimeout {
            giveUp()
            return
        }
        probedAt = current
        phoneLink.probeWhileScreenOff()
    }

    // 앱이 스스로 닫히는 기능이 없어, 값을 지우면 대기 화면으로 돌아간다
    private func giveUp() {
        phoneLink.forgetRun()
        stopWatching()
    }

    // SYNC 중엔 앞 상태라 믿지 않는다
    private static func isRunOver(_ linkState: PhoneLinkState) -> Bool {
        guard !linkState.isSyncing else { return false }
        return linkState.isUpdateRequired || (linkState.phoneState != nil && !linkState.isRunActive)
    }

    // 폰이 워치 앱을 켤 때 넘기는 설정과 같다
    private static var runningConfiguration: HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        return configuration
    }

    private static let checkInterval = Duration.seconds(60)
    private static let probeDelay = Duration.seconds(60)
    private static let giveUpTimeout = Duration.seconds(600)
}

private enum TrackerState {
    case idle
    /// 시작하거나 끝내는 중이다.
    case changing
    case running
}
