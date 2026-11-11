import HealthKit
import Testing

@testable import RuniverseWatch

@MainActor
struct WorkoutSessionTests {

    @Test
    func `폰이 러닝 중이라고 답하면 세션을 시작하고 받은 심박을 내보낸다`() throws {
        // given
        let fixture = Fixture()

        // when
        try fixture.connect(state(stateSequence: 1))
        fixture.tracker.deliver(148)

        // then
        #expect(fixture.tracker.calls == ["authorize", "start"])
        #expect(fixture.session.heartRateBpm == 148)
    }

    @Test
    func `직접 연 앱은 폰이 켤 때와 같은 달리기·실외로 시작한다`() throws {
        // given
        let fixture = Fixture()

        // when
        try fixture.connect(state(stateSequence: 1))

        // then
        let configuration = try #require(fixture.tracker.startedConfigurations.first)
        #expect(configuration.activityType == .running)
        #expect(configuration.locationType == .outdoor)
    }

    @Test
    func `폰이 워치 앱을 켜면 폰 답을 기다리지 않고 폰이 준 설정으로 시작한다`() {
        // given
        let fixture = Fixture()
        let configuration = HKWorkoutConfiguration()

        // when
        fixture.session.onLaunchedByPhone(configuration)

        // then
        #expect(fixture.tracker.calls == ["authorize", "start"])
        #expect(fixture.tracker.startedConfigurations.first === configuration)
    }

    @Test
    func `폰이 켠 직후 지난 러닝 상태가 남아 있어도 세션을 끝내지 않는다`() throws {
        // given -> 지난 러닝의 결과를 받아 둔 채 앱이 살아 있다
        let fixture = Fixture()
        try fixture.connect(finishedState(stateSequence: 1))

        // when -> 폰이 새 러닝으로 워치 앱을 켜고, 손목을 들었는데 폰 답이 3초 넘게 없다
        fixture.session.onLaunchedByPhone(HKWorkoutConfiguration())
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.timer.advance(by: .seconds(3))

        // then
        #expect(fixture.tracker.calls == ["authorize", "start"])
    }

    @Test
    func `러닝이 끝나면 세션을 끝내고 심박을 비운다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.tracker.deliver(148)

        // when
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2)))

        // then
        #expect(fixture.tracker.calls.last == "end")
        #expect(fixture.session.heartRateBpm == nil)
    }

    @Test
    func `러닝이 사라지면 세션을 끝낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.phoneLink.onReceived(stateUpdated(idleState(stateSequence: 2)))

        // then
        #expect(fixture.tracker.calls.last == "end")
    }

    @Test
    func `일시정지는 세션을 끝내지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2, status: .paused)))

        // then
        #expect(fixture.tracker.calls == ["authorize", "start"])
    }

    @Test
    func `폰이 업데이트를 요구하면 세션을 끝낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.phoneLink.onReceived(updateRequired)

        // then
        #expect(fixture.tracker.calls.last == "end")
    }

    @Test
    func `업데이트로 막힌 뒤엔 1분 물음도 보내지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onReceived(updateRequired)
        fixture.sent.removeAll()

        // when
        fixture.timer.advance(by: .seconds(180))

        // then
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `업데이트로 막힌 채면 폰이 켜도 세션을 시작하지 않는다`() throws {
        // given
        let fixture = Fixture()
        fixture.phoneLink.start()
        fixture.phoneLink.onReceived(updateRequired)

        // when
        fixture.session.onLaunchedByPhone(HKWorkoutConfiguration())

        // then
        #expect(fixture.tracker.calls.isEmpty)
    }

    @Test
    func `시작에 실패하면 이번 러닝엔 다시 시작하지 않는다`() throws {
        // given
        let fixture = Fixture()
        fixture.tracker.isStartSuccessful = false
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2)))

        // then
        #expect(fixture.tracker.calls == ["authorize", "start"])
    }

    @Test
    func `다른 앱에 밀려 세션이 끝나면 심박을 비우고 이번 러닝엔 다시 켜지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.tracker.deliver(148)

        // when
        fixture.tracker.endBySystem()
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2)))

        // then
        #expect(fixture.session.heartRateBpm == nil)
        #expect(fixture.tracker.calls == ["authorize", "start"])
    }

    @Test
    func `밀린 뒤 폰이 워치 앱을 다시 켜면 세션을 다시 시작한다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.tracker.endBySystem()

        // when
        fixture.session.onLaunchedByPhone(HKWorkoutConfiguration())

        // then
        #expect(fixture.tracker.calls == ["authorize", "start", "authorize", "start"])
    }

    @Test
    func `시작에 실패해도 다음 러닝에선 다시 시작한다`() throws {
        // given
        let fixture = Fixture()
        fixture.tracker.isStartSuccessful = false
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2)))
        fixture.tracker.isStartSuccessful = true

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 3)))

        // then
        #expect(fixture.tracker.calls == ["authorize", "start", "authorize", "start"])
    }

    @Test
    func `끝내는 중에 새 러닝이 오면 끝난 뒤에 시작한다`() throws {
        // given -> 끝내기가 아직 안 끝났다
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.tracker.holdsEnd = true
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2)))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 3)))

        // then
        #expect(fixture.tracker.calls == ["authorize", "start", "end"])

        // when
        fixture.tracker.finishEnd()

        // then
        #expect(fixture.tracker.calls == ["authorize", "start", "end", "authorize", "start"])
    }

    @Test
    func `시작하는 중에 러닝이 끝나면 시작이 끝나자마자 끝낸다`() throws {
        // given -> 시작이 아직 안 끝났다
        let fixture = Fixture()
        fixture.tracker.holdsStart = true
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2)))

        // when
        fixture.tracker.finishStart()

        // then
        #expect(fixture.tracker.calls == ["authorize", "start", "end"])
    }

    @Test
    func `권한을 묻는 사이 러닝이 끝나면 세션을 시작하지 않는다`() throws {
        // given -> 권한 창이 떠 있다
        let fixture = Fixture()
        fixture.tracker.holdsAuthorization = true
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2)))

        // when
        fixture.tracker.finishAuthorization()

        // then
        #expect(fixture.tracker.calls == ["authorize"])
    }

    @Test
    func `끝낸 뒤 늦게 온 심박은 버린다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2)))

        // when
        fixture.tracker.deliver(150)

        // then
        #expect(fixture.session.heartRateBpm == nil)
    }

    @Test
    func `되찾은 세션은 폰이 러닝 중이라고 하면 그대로 둔다`() throws {
        // given
        let fixture = Fixture()
        fixture.tracker.isRecoverable = true

        // when
        fixture.session.onRecoveryRequested()
        try fixture.connect(state(stateSequence: 1))

        // then
        #expect(fixture.tracker.calls == ["recover"])
    }

    @Test
    func `되찾은 세션은 폰이 러닝이 없다고 하면 끝낸다`() throws {
        // given
        let fixture = Fixture()
        fixture.tracker.isRecoverable = true

        // when
        fixture.session.onRecoveryRequested()
        try fixture.connect(idleState(stateSequence: 1))

        // then
        #expect(fixture.tracker.calls == ["recover", "end"])
    }

    @Test
    func `되찾는 사이 폰이 러닝이 없다고 하면 되찾은 세션을 바로 끝낸다`() throws {
        // given -> 되찾기가 아직 안 끝났다
        let fixture = Fixture()
        fixture.tracker.isRecoverable = true
        fixture.tracker.holdsRecover = true
        fixture.session.onRecoveryRequested()
        try fixture.connect(idleState(stateSequence: 1))

        // when
        fixture.tracker.finishRecover()

        // then
        #expect(fixture.tracker.calls == ["recover", "end"])
    }

    @Test
    func `되찾는 사이 폰이 러닝 중이라고 하면 새로 시작하지 않고 되찾은 세션을 쓴다`() throws {
        // given -> 되찾기가 아직 안 끝났다
        let fixture = Fixture()
        fixture.tracker.isRecoverable = true
        fixture.tracker.holdsRecover = true
        fixture.session.onRecoveryRequested()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.tracker.finishRecover()

        // then
        #expect(fixture.tracker.calls == ["recover"])
    }

    @Test
    func `되찾을 세션이 없으면 폰이 러닝 중이라고 할 때 새로 시작한다`() throws {
        // given
        let fixture = Fixture()

        // when
        fixture.session.onRecoveryRequested()
        try fixture.connect(state(stateSequence: 1))

        // then
        #expect(fixture.tracker.calls == ["recover", "authorize", "start"])
    }

    @Test
    func `되찾은 세션도 폰이 10분 넘게 답하지 않으면 끝낸다`() {
        // given
        let fixture = Fixture()
        fixture.tracker.isRecoverable = true
        fixture.session.onRecoveryRequested()

        // when
        fixture.timer.advance(by: .seconds(720))

        // then
        #expect(fixture.tracker.calls == ["recover", "end"])
    }

    @Test
    func `화면이 꺼진 동안 폰 소식이 1분 넘게 없으면 SYNC로 묻는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.timer.advance(by: .seconds(60))

        // then
        #expect(fixture.sent.count { $0.sync != nil } == 1)
    }

    @Test
    func `화면이 켜져 있으면 3초 감시에 맡기고 따로 묻지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.sent.removeAll()
        fixture.slept += .seconds(60)

        // when
        fixture.tracker.deliver(148)

        // then
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `CPU가 잠들어 타이머가 밀려도 심박이 오면 실제 시각으로 묻는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.slept += .seconds(150)
        fixture.tracker.deliver(148)

        // then
        #expect(fixture.sent.count { $0.sync != nil } == 1)
    }

    @Test
    func `심박이 자주 와도 1분에 한 번만 묻는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.slept += .seconds(60)

        // when
        for _ in 0..<10 {
            fixture.slept += .seconds(1)
            fixture.tracker.deliver(148)
        }

        // then
        #expect(fixture.sent.count { $0.sync != nil } == 1)
    }

    @Test
    func `물어본 뒤 답이 없는 채 10분이 넘으면 러닝을 접고 세션을 끝낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when -> 첫 물음은 1분째, 10분 뒤인 11분째 마지막으로 묻고 1분을 더 기다린다
        fixture.timer.advance(by: .seconds(720))

        // then
        #expect(fixture.phoneLink.state.phoneState == nil)
        #expect(fixture.tracker.calls.last == "end")
    }

    @Test
    func `답이 없어도 10분이 안 되면 세션을 유지한다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.timer.advance(by: .seconds(660))

        // then
        #expect(fixture.phoneLink.state.phoneState != nil)
        #expect(fixture.tracker.calls == ["authorize", "start"])
    }

    @Test
    func `오래 조용했다가 깨어나도 물어보기 전엔 세션을 끝내지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.slept += .seconds(3600)
        fixture.tracker.deliver(148)

        // then
        #expect(fixture.tracker.calls == ["authorize", "start"])
        #expect(fixture.sent.count { $0.sync != nil } == 1)
    }

    @Test
    func `한 번 물은 뒤 오래 잠들었다 깨어나면 끝내지 않고 다시 묻는다`() throws {
        // given -> 1분째 물었지만 답이 없다
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.timer.advance(by: .seconds(60))
        fixture.sent.removeAll()

        // when
        fixture.slept += .seconds(600)
        fixture.tracker.deliver(148)

        // then
        #expect(fixture.tracker.calls == ["authorize", "start"])
        #expect(fixture.sent.count { $0.sync != nil } == 1)
    }

    @Test
    func `다시 물은 뒤에도 답이 없으면 그때 세션을 끝낸다`() throws {
        // given -> 오래 잠들었다 깨어나 다시 물었다
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.timer.advance(by: .seconds(60))
        fixture.slept += .seconds(600)
        fixture.tracker.deliver(148)

        // when
        fixture.slept += .seconds(60)
        fixture.tracker.deliver(148)

        // then
        #expect(fixture.phoneLink.state.phoneState == nil)
        #expect(fixture.tracker.calls.last == "end")
    }

    @Test
    func `심박이 5분 넘는 간격으로 와도 답이 없으면 세션을 끝낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when -> 타이머는 잠들어 멈추고 심박만 띄엄띄엄 온다
        for _ in 0..<4 {
            fixture.slept += .seconds(302)
            fixture.tracker.deliver(148)
        }

        // then
        #expect(fixture.tracker.calls.last == "end")
    }

    @Test
    func `SYNC에 답이 오면 10분을 처음부터 다시 센다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.timer.advance(by: .seconds(540))

        // when -> 9분째 폰이 답한다
        try fixture.answerSync(state(stateSequence: 2))
        fixture.timer.advance(by: .seconds(240))

        // then -> 그 뒤 4분이 지나 처음부터 세면 13분이어도 끝나지 않는다
        #expect(fixture.tracker.calls == ["authorize", "start"])
    }

    @Test
    func `폰을 잃고 끝난 뒤 다시 러닝을 받으면 10분을 처음부터 센다`() throws {
        // given -> 폰을 잃어 세션이 끝났다가 앱을 다시 열어 러닝을 받았다
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.timer.advance(by: .seconds(720))
        try fixture.connect(state(stateSequence: 3))

        // when
        fixture.timer.advance(by: .seconds(120))

        // then
        #expect(fixture.tracker.calls == ["authorize", "start", "end", "authorize", "start"])
    }
}

@MainActor
private final class Fixture {
    var sent: [WatchMessage] = []
    let timer = FakeTimer()
    let tracker = FakeWorkoutTracker()
    /// CPU가 잠들어 타이머는 안 울리고 시계만 흐른 시간이다.
    var slept = Duration.zero
    private let startedAt = ContinuousClock.now
    private var nextId = 0

    lazy var phoneLink = PhoneLink(
        send: { [unowned self] in sent.append($0) },
        watchVersion: "1.0.0",
        newId: { [unowned self] in
            nextId += 1
            return "id-\(nextId)"
        },
        schedule: timer.schedule
    )

    lazy var session = WorkoutSession(
        phoneLink: phoneLink,
        tracker: tracker,
        now: { [unowned self] in startedAt + timer.now + slept },
        schedule: timer.schedule
    )

    // 앱을 열어 SYNC를 보내고 폰 답을 받는다
    func connect(_ initial: PhoneState) throws {
        _ = session
        phoneLink.start()
        try answerSync(initial)
        sent.removeAll()
    }

    func answerSync(_ state: PhoneState) throws {
        let sync = try #require(sent.last { $0.sync != nil }?.sync)
        phoneLink.onReceived(.synced(WatchSynced(syncId: sync.syncId, state: state, birthday: nil, photos: [])))
    }
}

// 권한·시작·되찾기·끝내기는 그 자리에서 마치고, 붙잡으라고 하면 finish*를 부를 때 마친다
@MainActor
private final class FakeWorkoutTracker: WorkoutTracker {
    var onHeartRate: ((Int?) -> Void)?
    var onEndedBySystem: (() -> Void)?

    private(set) var calls: [String] = []
    private(set) var startedConfigurations: [HKWorkoutConfiguration] = []
    var isStartSuccessful = true
    var isRecoverable = false
    var holdsAuthorization = false
    var holdsStart = false
    var holdsRecover = false
    var holdsEnd = false
    private var pendingAuthorization: (() -> Void)?
    private var pendingStart: ((Bool) -> Void)?
    private var pendingRecover: ((Bool) -> Void)?
    private var pendingEnd: (() -> Void)?

    func requestAuthorization(completion: @escaping () -> Void) {
        calls.append("authorize")
        if holdsAuthorization { pendingAuthorization = completion } else { completion() }
    }

    func start(configuration: HKWorkoutConfiguration, completion: @escaping (Bool) -> Void) {
        calls.append("start")
        startedConfigurations.append(configuration)
        if holdsStart { pendingStart = completion } else { completion(isStartSuccessful) }
    }

    func recover(completion: @escaping (Bool) -> Void) {
        calls.append("recover")
        if holdsRecover { pendingRecover = completion } else { completion(isRecoverable) }
    }

    func end(completion: @escaping () -> Void) {
        calls.append("end")
        if holdsEnd { pendingEnd = completion } else { completion() }
    }

    func finishAuthorization() {
        pendingAuthorization?()
        pendingAuthorization = nil
    }

    func finishStart() {
        pendingStart?(isStartSuccessful)
        pendingStart = nil
    }

    func finishRecover() {
        pendingRecover?(isRecoverable)
        pendingRecover = nil
    }

    func finishEnd() {
        pendingEnd?()
        pendingEnd = nil
    }

    func deliver(_ heartRateBpm: Int?) {
        onHeartRate?(heartRateBpm)
    }

    func endBySystem() {
        onEndedBySystem?()
    }
}

extension WatchMessage {
    fileprivate var sync: WatchSync? {
        guard case .sync(let sync) = self else { return nil }
        return sync
    }
}

private let updateRequired = PhoneMessage.error(
    PhoneError(code: "WATCH_UPDATE_REQUIRED", message: "워치 앱 업데이트 필요", sourceType: "WATCH_SYNC", requestId: nil)
)

private func stateUpdated(_ state: PhoneState) -> PhoneMessage {
    .stateUpdated(WatchStateUpdated(state: state))
}

private func idleState(stateSequence: Int64) -> PhoneState {
    PhoneState(phoneInstanceId: "p1", stateSequence: stateSequence, statusVersion: 0, lastRequestId: nil, run: nil)
}

private func finishedState(stateSequence: Int64) -> PhoneState {
    state(stateSequence: stateSequence, status: .finished)
}

private func state(stateSequence: Int64, status: RunStatus = .running) -> PhoneState {
    PhoneState(
        phoneInstanceId: "p1",
        stateSequence: stateSequence,
        statusVersion: 0,
        lastRequestId: nil,
        run: RunState(
            runningRoomId: 812,
            type: .solo,
            status: status,
            targetDistanceMeters: nil,
            isServerConnected: true,
            isPenaltyApplicable: false,
            me: MyRecord(
                distanceMeters: 1000,
                elapsedSeconds: 300,
                currentPaceSecondsPerKm: nil,
                caloriesKcal: nil,
                cadenceSpm: nil
            ),
            players: [],
            finish: nil,
            result: nil
        )
    )
}
