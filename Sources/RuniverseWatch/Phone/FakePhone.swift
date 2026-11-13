#if DEBUG
    import Foundation
    import ImageIO
    import UniformTypeIdentifiers

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
        private var comboTicker: Task<Void, Never>?
        private var comboEventCount = 0

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
                photos: fakeRun.sendsPhotos ? Self.samplePhotos : []
            )
            reply { [weak self] in self?.onReceived?(.synced(synced)) }
            if fakeRun != .phoneLost { startTicking() }
            if fakeRun.ticksCombo { startComboTicking() }
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
            run = copy(run, status: status, me: run.me, players: run.players, result: result)
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

        // 콤보가 오르다 끊기길 되풀이해 작은 순간·큰 순간·끊김을 차례로 본다
        private func startComboTicking() {
            guard comboTicker == nil else { return }
            comboTicker = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: Self.comboInterval)
                    guard let self else { return }
                    advanceCombo()
                }
            }
        }

        private func advanceCombo() {
            guard run.status == .running,
                let index = run.players.firstIndex(where: { $0.userId == Self.comboUserId })
            else { return }
            let player = run.players[index]
            let comboCount = player.comboCount >= Self.breakingComboCount ? 0 : player.comboCount + 1
            let kind: ComboKind =
                if comboCount == 0 {
                    .break
                } else if Self.milestoneComboCounts.contains(comboCount) {
                    .milestone
                } else {
                    .tick
                }
            var players = run.players
            players[index] = Player(
                userId: player.userId,
                nickname: player.nickname,
                colorSlot: player.colorSlot,
                distanceMeters: player.distanceMeters,
                currentPaceSecondsPerKm: player.currentPaceSecondsPerKm,
                status: player.status,
                gapMeters: player.gapMeters,
                comboCount: comboCount,
                maxComboCount: max(player.maxComboCount, comboCount),
                isStale: player.isStale
            )
            run = copy(run, status: run.status, me: run.me, players: players, result: run.result)
            comboEventCount += 1
            let combo = WatchComboTriggered(
                eventId: "fake-combo-\(comboEventCount)",
                userId: player.userId,
                comboCount: comboCount,
                kind: kind
            )
            onReceived?(.comboTriggered(combo))
            // 폰처럼 콤보를 알린 뒤 오른 숫자가 든 상태도 바로 보낸다
            onReceived?(.stateUpdated(WatchStateUpdated(state: nextState())))
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
            run = copy(run, status: run.status, me: advancedMe, players: run.players, result: run.result)
        }

        private func copy(
            _ run: RunState,
            status: RunStatus,
            me: MyRecord,
            players: [Player],
            result: RunResult?
        ) -> RunState {
            RunState(
                runningRoomId: run.runningRoomId,
                type: run.type,
                status: status,
                targetDistanceMeters: run.targetDistanceMeters,
                isServerConnected: run.isServerConnected,
                isPenaltyApplicable: run.isPenaltyApplicable,
                me: me,
                players: players,
                finish: run.finish,
                result: result
            )
        }

        private static func jpegBase64(_ image: CGImage) -> String? {
            let jpeg = NSMutableData()
            guard
                let destination = CGImageDestinationCreateWithData(jpeg, UTType.jpeg.identifier as CFString, 1, nil)
            else { return nil }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else { return nil }
            return (jpeg as Data).base64EncodedString()
        }

        // 폰처럼 JPEG base64로 보내 워치의 사진 풀기를 거친다
        private static let samplePhotos = RunSamples.brightPhotos.compactMap { userId, image in
            jpegBase64(image).map { PlayerPhoto(userId: userId, jpegBase64: $0) }
        }

        private static let metersPerTick = 3

        // 큰 순간 1.2초가 끝나고 작은 순간이 따로 보이는 간격이다
        private static let comboInterval = Duration.seconds(3)
        private static let comboUserId = "u2"
        private static let breakingComboCount = 12
        private static let milestoneComboCounts: Set<Int> = [1, 3, 5, 10]
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
        case combo
        case photos

        var run: RunState {
            switch self {
            case .party, .phoneLost, .combo, .photos: RunSamples.party
            case .solo: RunSamples.solo
            case .longValues: RunSamples.longValues
            case .paused: RunSamples.paused
            case .playerStatuses: RunSamples.playerStatuses
            case .serverLost: RunSamples.serverLost
            case .playerEdges: RunSamples.playerEdges
            }
        }

        // 사진을 그린 채 고리·큰 순간까지 보려고 사진 경우도 콤보를 올린다
        var ticksCombo: Bool { self == .combo || self == .photos }
        var sendsPhotos: Bool { self == .photos }
    }
#endif
