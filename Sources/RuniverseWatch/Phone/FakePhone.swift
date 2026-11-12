#if DEBUG
    import Foundation

    /// 폰 없이 러닝 화면을 볼 때 폰 대신 답한다. 개발용 앱을 실행 인자 `-fakeRun <경우>`로 켠다.
    @MainActor
    final class FakePhone {
        private let fakeRun: FakeRun
        private var run: RunState
        private var stateSequence: Int64 = 0
        private var statusVersion = 0
        private var lastRequestId: String?
        private var hasAnswered = false
        private var onReceived: (@MainActor (PhoneMessage) -> Void)?
        private var ticker: Task<Void, Never>?

        /// 경우 이름이 없거나 모르는 이름이면 nil이다.
        init?(fakeRunName: String?) {
            guard let fakeRunName, let fakeRun = FakeRun(rawValue: fakeRunName) else { return nil }
            self.fakeRun = fakeRun
            run = fakeRun.run
        }

        func start(
            onReceived: @escaping @MainActor (PhoneMessage) -> Void,
            onOpened: @escaping @MainActor () -> Void
        ) {
            self.onReceived = onReceived
            reply(onOpened)
        }

        func send(_ message: WatchMessage) {
            switch message {
            case .sync(let sync): answerSync(sync)
            case .pause(let pause): applyCommand(requestId: pause.requestId, status: .paused)
            case .resume(let resume): applyCommand(requestId: resume.requestId, status: .running)
            case .finish(let finish): applyCommand(requestId: finish.requestId, status: .finished)
            case .visibilityUpdate: break
            }
        }

        private func answerSync(_ sync: WatchSync) {
            // 폰 끊김은 첫 답 뒤로 조용하다 — 워치가 3초 뒤 `폰 연결 확인 중`을 띄운다
            if fakeRun == .phoneLost, hasAnswered { return }
            hasAnswered = true
            let synced = WatchSynced(
                syncId: sync.syncId,
                state: nextState(),
                birthday: RunSamples.birthday,
                photos: []
            )
            reply { [weak self] in self?.onReceived?(.synced(synced)) }
            if fakeRun != .phoneLost { startTicking() }
        }

        // 폰처럼 명령을 반영하면 1초를 기다리지 않고 바로 보낸다
        private func applyCommand(requestId: String, status: RunStatus) {
            if fakeRun == .phoneLost { return }
            statusVersion += 1
            lastRequestId = requestId
            let result =
                status == .finished
                ? RunResult(
                    isServerConfirmed: true,
                    totalDistanceMeters: run.me.distanceMeters,
                    averagePaceSecondsPerKm: run.me.currentPaceSecondsPerKm,
                    elapsedSeconds: run.me.elapsedSeconds
                )
                : nil
            run = copy(run, status: status, me: run.me, result: result)
            let stateUpdated = WatchStateUpdated(state: nextState())
            reply { [weak self] in self?.onReceived?(.stateUpdated(stateUpdated)) }
        }

        // 폰처럼 1초마다 상태를 보낸다
        private func startTicking() {
            guard ticker == nil else { return }
            ticker = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    guard let self else { return }
                    advance()
                    onReceived?(.stateUpdated(WatchStateUpdated(state: nextState())))
                }
            }
        }

        // 받는 쪽이 보내는 도중에 답이 끼어들지 않게 다음 차례로 미룬다
        private func reply(_ action: @escaping @MainActor () -> Void) {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { action() }
            }
        }

        private func nextState() -> PhoneState {
            stateSequence += 1
            return PhoneState(
                phoneInstanceId: "fake",
                stateSequence: stateSequence,
                statusVersion: statusVersion,
                lastRequestId: lastRequestId,
                run: run
            )
        }

        // 달리는 중이면 시간과 거리가 움직여야 같은 폭 숫자를 볼 수 있다
        private func advance() {
            guard run.status == .running else { return }
            let me = run.me
            let advancedMe = MyRecord(
                distanceMeters: me.distanceMeters + Self.metersPerTick,
                elapsedSeconds: me.elapsedSeconds + 1,
                currentPaceSecondsPerKm: me.currentPaceSecondsPerKm,
                caloriesKcal: me.caloriesKcal,
                cadenceSpm: me.cadenceSpm
            )
            run = copy(run, status: run.status, me: advancedMe, result: run.result)
        }

        private func copy(_ run: RunState, status: RunStatus, me: MyRecord, result: RunResult?) -> RunState {
            RunState(
                runningRoomId: run.runningRoomId,
                type: run.type,
                status: status,
                targetDistanceMeters: run.targetDistanceMeters,
                isServerConnected: run.isServerConnected,
                isPenaltyApplicable: run.isPenaltyApplicable,
                me: me,
                players: run.players,
                finish: run.finish,
                result: result
            )
        }

        private static let metersPerTick = 3
    }

    /// 가짜 폰이 보낼 러닝이다. 실행 인자에 이름 그대로 쓴다.
    enum FakeRun: String {
        case party
        case solo
        case longValues
        case paused
        case playerStatuses
        case serverLost
        case phoneLost
        case playerEdges

        var run: RunState {
            switch self {
            case .party, .phoneLost: RunSamples.party
            case .solo: RunSamples.solo
            case .longValues: RunSamples.longValues
            case .paused: RunSamples.paused
            case .playerStatuses: RunSamples.playerStatuses
            case .serverLost: RunSamples.serverLost
            case .playerEdges: RunSamples.playerEdges
            }
        }
    }
#endif
