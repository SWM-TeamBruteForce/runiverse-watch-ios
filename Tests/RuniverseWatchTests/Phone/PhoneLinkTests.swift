import Testing

@testable import RuniverseWatch

@MainActor
struct PhoneLinkTests {

    @Test
    func `앱을 열면 SYNC를 보내고 SYNCED를 받을 때까지 잠근다`() throws {
        // given
        let fixture = Fixture()

        // when
        fixture.phoneLink.start()

        // then
        #expect(fixture.sent.count == 1)
        let sync = try #require(fixture.sent.first?.sync)
        #expect(fixture.phoneLink.state.isLocked)

        // when -> 폰이 답한다
        fixture.phoneLink.onReceived(synced(sync.syncId, state(stateSequence: 1)))

        // then
        let linkState = fixture.phoneLink.state
        #expect(!linkState.isLocked)
        #expect(linkState.phoneState?.stateSequence == 1)
    }

    @Test
    func `SYNC에 워치 버전을 싣는다`() throws {
        // given
        let fixture = Fixture()

        // when
        fixture.phoneLink.start()

        // then
        #expect(fixture.sent.count == 1)
        let sync = try #require(fixture.sent.first?.sync)
        #expect(sync.watchVersion == watchVersion)
    }

    @Test
    func `화면이 꺼져 있어도 통로가 열리면 SYNC를 새 번호로 다시 보낸다`() throws {
        // given -> 통로가 열리기 전에 보낸 SYNC는 버려졌다
        let fixture = Fixture()
        fixture.phoneLink.start()
        let droppedSync = try #require(fixture.sent.first?.sync)
        fixture.sent.removeAll()

        // when
        fixture.phoneLink.onChannelOpened()

        // then
        #expect(fixture.sent.count == 1)
        let sync = try #require(fixture.sent.first?.sync)
        #expect(sync.syncId != droppedSync.syncId)

        // when -> 폰이 새 SYNC에 답한다
        fixture.phoneLink.onReceived(synced(sync.syncId, state(stateSequence: 1)))

        // then
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `화면이 켜져 있으면 통로가 열릴 때 켜짐 신호도 다시 보낸다`() {
        // given
        let fixture = Fixture()
        fixture.phoneLink.start()
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.sent.removeAll()

        // when
        fixture.phoneLink.onChannelOpened()

        // then
        #expect(fixture.sent.contains { $0.isVisible == true })
        #expect(fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `연결된 채 통로가 다시 열리면 SYNC 없이 켜짐 신호만 다시 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.sent.removeAll()

        // when -> 폰이 잠깐 멀어졌다 돌아온다
        fixture.phoneLink.onChannelOpened()

        // then
        #expect(fixture.sent.contains { $0.isVisible == true })
        #expect(!fixture.sent.contains { $0.sync != nil })
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `보낸 적 없는 syncId의 SYNCED는 버린다`() {
        // given
        let fixture = Fixture()
        fixture.phoneLink.start()

        // when
        fixture.phoneLink.onReceived(synced("모르는-id", state(stateSequence: 1)))

        // then
        #expect(fixture.phoneLink.state.isSyncing)
        #expect(fixture.phoneLink.state.phoneState == nil)
    }

    @Test
    func `러닝 중 화면이 켜져 있는데 3초 동안 못 받으면 폰 연결 확인 중으로 바꾸고 SYNC를 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.sent.removeAll()

        // when
        fixture.timer.advance(by: .milliseconds(3_001))

        // then
        let linkState = fixture.phoneLink.state
        #expect(!linkState.isPhoneReachable)
        #expect(linkState.isLocked)
        #expect(linkState.phoneState?.stateSequence == 1)
        #expect(fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `화면이 꺼져 있으면 오래 못 받아도 연결 상태를 바꾸지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.timer.advance(by: .seconds(60))

        // then
        #expect(fixture.phoneLink.state.isPhoneReachable)
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `상태가 계속 오면 3초가 지나도 연결된 채로 둔다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onScreenVisibilityChanged(true)

        // when
        for stateSequence in Int64(2)...5 {
            fixture.timer.advance(by: .seconds(1))
            fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: stateSequence)))
        }
        fixture.timer.advance(by: .seconds(2))

        // then
        #expect(fixture.phoneLink.state.isPhoneReachable)
        #expect(fixture.phoneLink.state.phoneState?.stateSequence == 5)
    }

    @Test
    func `러닝이 없을 때 화면으로 돌아와 3초 동안 답이 없으면 폰 연결 확인 중으로 바꾸고 SYNC를 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(idleState(stateSequence: 1))
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.phoneLink.onReceived(stateUpdated(idleState(stateSequence: 2)))
        fixture.phoneLink.onScreenVisibilityChanged(false)
        fixture.sent.removeAll()

        // when -> 폰이 사라진 뒤 화면으로 돌아온다
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.timer.advance(by: .milliseconds(3_001))

        // then
        #expect(!fixture.phoneLink.state.isPhoneReachable)
        #expect(fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `러닝이 없을 때 화면으로 돌아와 폰이 상태를 보내면 연결된 채로 둔다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(idleState(stateSequence: 1))

        // when
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.timer.advance(by: .seconds(1))
        fixture.phoneLink.onReceived(stateUpdated(idleState(stateSequence: 2)))
        fixture.timer.advance(by: .seconds(5))

        // then
        #expect(fixture.phoneLink.state.isPhoneReachable)
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `화면이 꺼져 있으면 SYNC를 한 번만 보낸다`() {
        // given
        let fixture = Fixture()

        // when
        fixture.phoneLink.start()
        fixture.timer.advance(by: .milliseconds(6_001))

        // then
        #expect(fixture.sent.compactMap(\.sync).count == 1)
        #expect(fixture.phoneLink.state.isSyncing)
        #expect(!fixture.phoneLink.state.isPhoneReachable)
    }

    @Test
    func `SYNC 중에 화면이 켜지면 SYNC를 다시 보내고 3초마다 되풀이한다`() {
        // given
        let fixture = Fixture()
        fixture.phoneLink.start()
        fixture.timer.advance(by: .milliseconds(3_001))
        fixture.sent.removeAll()

        // when
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.timer.advance(by: .milliseconds(3_001))

        // then
        #expect(fixture.sent.compactMap(\.sync).count == 2)
    }

    @Test
    func `SYNC 중에 온 상태는 버린다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2, phoneInstanceId: "p2")))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 3)))

        // then
        #expect(fixture.phoneLink.state.isSyncing)
        #expect(fixture.phoneLink.state.phoneState?.stateSequence == 1)
    }

    @Test
    func `화면이 켜져 있는 동안 10초마다 켜짐 신호를 보내고 꺼지면 꺼짐 신호를 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.timer.advance(by: .milliseconds(20_001))

        // then
        #expect(fixture.sent.compactMap(\.isVisible).filter { $0 }.count == 3)

        // when -> 화면이 꺼진다
        fixture.phoneLink.onScreenVisibilityChanged(false)
        fixture.timer.advance(by: .milliseconds(20_001))

        // then
        let visibilities = fixture.sent.compactMap(\.isVisible)
        #expect(visibilities.last == false)
        #expect(visibilities.filter { $0 }.count == 3)
    }

    @Test
    func `지난 번호의 상태는 버린다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 5))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 4, distanceMeters: 999)))

        // then
        #expect(fixture.phoneLink.state.phoneState?.stateSequence == 5)
    }

    @Test
    func `폰 앱이 다시 켜져 phoneInstanceId가 바뀌면 SYNC를 보내고 그 상태는 쓰지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 5))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 1, phoneInstanceId: "p2")))

        // then
        #expect(fixture.phoneLink.state.phoneState?.phoneInstanceId == "p1")
        #expect(fixture.phoneLink.state.isSyncing)
        #expect(fixture.sent.count == 1)
        #expect(fixture.sent.first?.sync != nil)
    }

    @Test
    func `모르는 방 번호가 오면 SYNC를 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1, runningRoomId: 812))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2, runningRoomId: 900)))

        // then
        #expect(fixture.phoneLink.state.phoneState?.run?.runningRoomId == 812)
        #expect(fixture.sent.count == 1)
        #expect(fixture.sent.first?.sync != nil)
    }

    @Test
    func `방 번호가 처음 오면 SYNC를 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1, runningRoomId: nil))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2, runningRoomId: 812)))

        // then
        #expect(fixture.phoneLink.state.phoneState?.stateSequence == 1)
        #expect(fixture.sent.count == 1)
        #expect(fixture.sent.first?.sync != nil)
    }

    @Test
    func `러닝이 없다가 방 번호 없는 러닝이 오면 SYNC 없이 받는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(idleState(stateSequence: 1))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2, runningRoomId: nil)))

        // then
        #expect(fixture.phoneLink.state.phoneState?.stateSequence == 2)
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `방 번호가 있던 러닝이 사라지면 SYNC 없이 run nil을 받는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1, runningRoomId: 812))

        // when
        fixture.phoneLink.onReceived(stateUpdated(idleState(stateSequence: 2)))

        // then
        let linkState = fixture.phoneLink.state
        #expect(linkState.phoneState?.stateSequence == 2)
        #expect(linkState.phoneState?.run == nil)
        #expect(!linkState.isSyncing)
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `방 번호가 있던 러닝 다음에 방 번호 없는 러닝이 오면 SYNC 없이 받는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1, runningRoomId: 812))

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2, runningRoomId: nil)))

        // then
        let linkState = fixture.phoneLink.state
        #expect(linkState.phoneState?.stateSequence == 2)
        #expect(!linkState.isSyncing)
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `명령은 처리됐다는 상태가 올 때까지 잠근다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1, statusVersion: 4))

        // when
        let isSent = fixture.phoneLink.pause()

        // then
        #expect(isSent)
        #expect(fixture.sent.count == 1)
        let pause = try #require(fixture.sent.first?.pause)
        let expected = WatchPause(
            requestId: pause.requestId,
            phoneInstanceId: "p1",
            runningRoomId: 812,
            statusVersion: 4
        )
        #expect(pause == expected)
        #expect(fixture.phoneLink.state.isLocked)

        // when -> 폰이 반영한 상태를 보낸다
        fixture.phoneLink.onReceived(
            stateUpdated(state(stateSequence: 2, statusVersion: 5, lastRequestId: pause.requestId))
        )

        // then
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `방 번호 없는 러닝에서 누르면 방 번호 nil 그대로 명령을 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1, runningRoomId: nil, statusVersion: 4))

        // when
        let isSent = fixture.phoneLink.pause()

        // then
        #expect(isSent)
        #expect(fixture.sent.count == 1)
        let pause = try #require(fixture.sent.first?.pause)
        let expected = WatchPause(
            requestId: pause.requestId,
            phoneInstanceId: "p1",
            runningRoomId: nil,
            statusVersion: 4
        )
        #expect(pause == expected)
    }

    @Test
    func `다른 명령이 처리된 상태로는 잠금을 풀지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.pause()

        // when
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2, lastRequestId: "폰에서-누른-것")))

        // then
        #expect(fixture.phoneLink.state.isLocked)
    }

    @Test
    func `보낸 명령이 종료인지 구분하고 답을 받으면 지운다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        _ = fixture.phoneLink.pause()

        // then
        #expect(!fixture.phoneLink.state.isFinishPending)

        // when -> 일시정지가 처리된 뒤 종료를 보낸다
        let pause = try #require(fixture.sent.first?.pause)
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2, lastRequestId: pause.requestId)))
        _ = fixture.phoneLink.finish(forced: false)

        // then
        #expect(fixture.phoneLink.state.isFinishPending)

        // when -> 폰이 반영한 상태를 보낸다
        let finish = try #require(fixture.sent.last?.finish)
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 3, lastRequestId: finish.requestId)))

        // then
        #expect(!fixture.phoneLink.state.isFinishPending)
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `일시정지를 거절받으면 잠금을 푼다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.pause()
        let pause = try #require(fixture.sent.first?.pause)

        // when
        fixture.phoneLink.onReceived(rejected(requestId: pause.requestId, sourceType: "WATCH_PAUSE"))

        // then
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `일시정지에 3초 동안 답이 없어도 종료 대기로 보지 않고 SYNC만 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.pause()

        // when
        fixture.timer.advance(by: .milliseconds(3_001))

        // then
        let linkState = fixture.phoneLink.state
        #expect(linkState.isCommandOverdue)
        #expect(linkState.isLocked)
        #expect(!linkState.isFinishPending)
        #expect(fixture.sent.compactMap(\.pause).count == 1)
        #expect(fixture.sent.last?.sync != nil)
    }

    @Test
    func `종료를 거절받으면 종료 대기를 지운다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.finish(forced: false)
        let finish = try #require(fixture.sent.first?.finish)

        // when
        fixture.phoneLink.onReceived(rejected(requestId: finish.requestId, sourceType: "WATCH_FINISH"))

        // then
        #expect(!fixture.phoneLink.state.isFinishPending)
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `명령에 3초 동안 답이 없으면 SYNC를 보내고 명령은 다시 보내지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.finish(forced: false)

        // when
        fixture.timer.advance(by: .milliseconds(3_001))

        // then
        let linkState = fixture.phoneLink.state
        #expect(linkState.isCommandOverdue)
        #expect(linkState.isFinishPending)
        #expect(linkState.isLocked)
        #expect(fixture.sent.compactMap(\.finish).count == 1)
        #expect(fixture.sent.last?.sync != nil)
    }

    @Test
    func `명령에 답이 없어 SYNC를 보낸 뒤 늦게 SYNCED가 오면 잠금을 푼다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.finish(forced: false)
        fixture.timer.advance(by: .milliseconds(3_001))
        let sync = try #require(fixture.sent.last?.sync)

        // when
        fixture.phoneLink.onReceived(synced(sync.syncId, state(stateSequence: 2)))

        // then
        let linkState = fixture.phoneLink.state
        #expect(!linkState.isFinishPending)
        #expect(!linkState.isLocked)
        #expect(!linkState.isCommandOverdue)
    }

    @Test
    func `폰 상태를 받기 전이거나 러닝이 없으면 명령을 보내지 않는다`() throws {
        // given
        let fixture = Fixture()

        // when & then -> 폰 상태를 아직 받지 않았다
        #expect(!fixture.phoneLink.pause())

        // given
        try fixture.connect(idleState(stateSequence: 1))

        // when & then -> 러닝이 없다
        #expect(!fixture.phoneLink.finish(forced: false))
        #expect(!fixture.sent.contains { $0.pause != nil || $0.finish != nil })
    }

    @Test
    func `요청 번호가 없거나 다른 ERROR로는 잠금을 풀지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.pause()

        // when
        fixture.phoneLink.onReceived(
            .error(PhoneError(code: "X", message: "m", sourceType: "WATCH_PAUSE", requestId: nil))
        )
        fixture.phoneLink.onReceived(
            .error(PhoneError(code: "X", message: "m", sourceType: "WATCH_PAUSE", requestId: "다른-명령"))
        )

        // then
        #expect(fixture.phoneLink.state.isLocked)
    }

    @Test
    func `거절 ERROR가 오면 잠금을 푼다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.resume()
        let resume = try #require(fixture.sent.first?.resume)

        // when
        fixture.phoneLink.onReceived(rejected(requestId: resume.requestId, sourceType: "WATCH_RESUME"))

        // then
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `앱을 열 때 업데이트 필요 ERROR가 오면 SYNC를 더 보내지 않는다`() throws {
        // given
        let fixture = Fixture()
        fixture.phoneLink.start()
        fixture.phoneLink.onScreenVisibilityChanged(true)
        let sync = try #require(fixture.sent.last { $0.sync != nil }?.sync)

        // when
        fixture.phoneLink.onReceived(updateRequired(requestId: sync.syncId))
        fixture.sent.removeAll()
        fixture.timer.advance(by: .milliseconds(10_001))

        // then
        #expect(fixture.phoneLink.state.isUpdateRequired)
        #expect(fixture.sent.isEmpty)
    }

    @Test
    func `러닝 중 번호가 다른 업데이트 필요 ERROR도 받아 러닝을 비우고 뒤에 온 상태는 버린다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.phoneLink.onReceived(updateRequired(requestId: "모르는-id"))
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2)))

        // then
        let linkState = fixture.phoneLink.state
        #expect(linkState.isUpdateRequired)
        #expect(linkState.phoneState == nil)
        #expect(!linkState.isRunActive)
    }

    @Test
    func `업데이트가 필요하면 화면이 켜지고 꺼져도 아무것도 보내지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onReceived(updateRequired(requestId: nil))

        // when
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.timer.advance(by: .milliseconds(3_001))
        fixture.phoneLink.onScreenVisibilityChanged(false)

        // then
        #expect(fixture.sent.isEmpty)
    }

    @Test
    func `업데이트가 필요하면 통로가 다시 열려도 아무것도 보내지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.phoneLink.onReceived(updateRequired(requestId: nil))
        fixture.sent.removeAll()

        // when
        fixture.phoneLink.onChannelOpened()

        // then
        #expect(fixture.sent.isEmpty)
    }

    @Test
    func `업데이트가 필요한 채 다시 열면 SYNC를 다시 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onReceived(updateRequired(requestId: nil))

        // when
        fixture.phoneLink.start()

        // then
        #expect(fixture.sent.count == 1)
        #expect(fixture.sent.first?.sync != nil)
        #expect(!fixture.phoneLink.state.isUpdateRequired)
    }

    @Test
    func `업데이트 거절 뒤 화면이 켜진 채 다시 열면 켜짐 신호를 다시 보낸다`() throws {
        // given
        let fixture = Fixture()
        fixture.phoneLink.start()
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.phoneLink.onReceived(updateRequired(requestId: nil))

        // when
        fixture.phoneLink.start()
        let sync = try #require(fixture.sent.last { $0.sync != nil }?.sync)
        fixture.phoneLink.onReceived(synced(sync.syncId, state(stateSequence: 1)))
        fixture.sent.removeAll()
        fixture.timer.advance(by: .milliseconds(10_001))

        // then
        #expect(fixture.sent.contains { $0.isVisible == true })
    }

    @Test
    func `업데이트 거절 전에 보낸 SYNC의 답이 늦게 와도 받지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.probeWhileScreenOff()
        let lateSync = try #require(fixture.sent.last { $0.sync != nil }?.sync)

        // when
        fixture.phoneLink.onReceived(updateRequired(requestId: nil))
        fixture.phoneLink.onReceived(synced(lateSync.syncId, state(stateSequence: 5)))

        // then
        #expect(fixture.phoneLink.state == PhoneLinkState(isUpdateRequired: true))
    }

    @Test
    func `잠겨 있으면 명령을 보내지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        _ = fixture.phoneLink.pause()

        // when
        let isSent = fixture.phoneLink.finish(forced: true)

        // then
        #expect(!isSent)
        #expect(fixture.sent.count == 1)
    }

    @Test
    func `같은 eventId의 콤보는 한 번만 내보낸다`() {
        // given
        let fixture = Fixture()
        var received: [WatchComboTriggered] = []
        fixture.phoneLink.onCombo = { received.append($0) }
        let combo = WatchComboTriggered(eventId: "e1", userId: "u2", comboCount: 3, kind: .milestone)

        // when
        fixture.phoneLink.onReceived(.comboTriggered(combo))
        fixture.phoneLink.onReceived(.comboTriggered(combo))

        // then
        #expect(received == [combo])
    }

    @Test
    func `일시정지·끊김은 진행 중인 러닝이고 끝났거나 러닝이 없으면 아니다`() {
        // when & then
        #expect(PhoneLinkState(phoneState: state(stateSequence: 1)).isRunActive)
        #expect(PhoneLinkState(phoneState: state(stateSequence: 1, status: .paused)).isRunActive)
        #expect(PhoneLinkState(phoneState: state(stateSequence: 1, status: .disconnected)).isRunActive)
        #expect(!PhoneLinkState(phoneState: state(stateSequence: 1, status: .finished)).isRunActive)
        #expect(!PhoneLinkState(phoneState: idleState(stateSequence: 1)).isRunActive)
        #expect(!PhoneLinkState().isRunActive)
    }

    @Test
    func `화면이 꺼져 있으면 물어볼 때 SYNC를 보낸다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))

        // when
        fixture.phoneLink.probeWhileScreenOff()

        // then
        #expect(fixture.sent.compactMap(\.sync).count == 1)
    }

    @Test
    func `화면이 켜져 있으면 물어봐도 SYNC를 보내지 않고 잠그지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.onScreenVisibilityChanged(true)
        fixture.sent.removeAll()

        // when
        fixture.phoneLink.probeWhileScreenOff()

        // then
        #expect(fixture.sent.compactMap(\.sync).isEmpty)
        #expect(!fixture.phoneLink.state.isLocked)
    }

    @Test
    func `러닝을 접으면 마지막 값을 지우고 다음 상태는 받지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.probeWhileScreenOff()

        // when
        fixture.phoneLink.forgetRun()
        fixture.phoneLink.onReceived(stateUpdated(state(stateSequence: 2)))

        // then
        #expect(fixture.phoneLink.state == PhoneLinkState())
    }

    @Test
    func `러닝을 접기 전에 보낸 SYNC의 답이 늦게 와도 받지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.probeWhileScreenOff()
        let lateSync = try #require(fixture.sent.last { $0.sync != nil }?.sync)

        // when
        fixture.phoneLink.forgetRun()
        fixture.phoneLink.onReceived(synced(lateSync.syncId, state(stateSequence: 5)))

        // then
        #expect(fixture.phoneLink.state == PhoneLinkState())
    }

    @Test
    func `러닝을 접은 뒤 3초가 지나도 연결 끊김으로 바뀌지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.probeWhileScreenOff()

        // when
        fixture.phoneLink.forgetRun()
        fixture.timer.advance(by: .milliseconds(3_001))

        // then
        #expect(fixture.phoneLink.state.isPhoneReachable)
    }

    @Test
    func `러닝을 접은 뒤 통로가 다시 열려도 SYNC를 보내지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.probeWhileScreenOff()
        fixture.phoneLink.forgetRun()
        fixture.sent.removeAll()

        // when -> 폰이 돌아온다
        fixture.phoneLink.onChannelOpened()

        // then
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `러닝을 접은 뒤 앱을 다시 열면 SYNCED로 러닝을 다시 받는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1))
        fixture.phoneLink.forgetRun()

        // when
        fixture.phoneLink.start()
        let sync = try #require(fixture.sent.last { $0.sync != nil }?.sync)
        fixture.phoneLink.onReceived(synced(sync.syncId, state(stateSequence: 5)))

        // then
        #expect(fixture.phoneLink.state.phoneState?.stateSequence == 5)
        #expect(fixture.phoneLink.state.isRunActive)
    }

    @Test
    func `닫은 결과는 같은 번호 쌍의 상태를 다시 받아도 띄우지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(finishedState(stateSequence: 1, statusVersion: 2))

        // when
        fixture.phoneLink.dismissResult()
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2, statusVersion: 2)))

        // then
        #expect(fixture.phoneLink.state.finishedRun == nil)
    }

    @Test
    func `결과를 받는 중에 닫으면 결과가 확정되어도 다시 띄우지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(finishedState(stateSequence: 1, statusVersion: 2, result: nil))

        // when
        fixture.phoneLink.dismissResult()
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2, statusVersion: 2)))

        // then
        #expect(fixture.phoneLink.state.finishedRun == nil)
    }

    @Test
    func `닫은 결과는 SYNCED로 다시 받아도 띄우지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(finishedState(stateSequence: 1, statusVersion: 2))
        fixture.phoneLink.dismissResult()

        // when
        fixture.phoneLink.start()
        let sync = try #require(fixture.sent.last { $0.sync != nil }?.sync)
        fixture.phoneLink.onReceived(synced(sync.syncId, finishedState(stateSequence: 2, statusVersion: 2)))

        // then
        #expect(fixture.phoneLink.state.finishedRun == nil)
    }

    @Test
    func `statusVersion이 다른 끝난 상태는 닫은 결과로 보지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(finishedState(stateSequence: 1, statusVersion: 2))
        fixture.phoneLink.dismissResult()

        // when
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2, statusVersion: 3)))

        // then
        #expect(fixture.phoneLink.state.finishedRun?.result == confirmedResult)
    }

    @Test
    func `폰 앱이 다시 켜져 번호가 달라지면 닫은 결과로 보지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(finishedState(stateSequence: 1, statusVersion: 2))
        fixture.phoneLink.dismissResult()

        // when
        fixture.phoneLink.start()
        let sync = try #require(fixture.sent.last { $0.sync != nil }?.sync)
        let restarted = finishedState(stateSequence: 1, statusVersion: 2, phoneInstanceId: "p2")
        fixture.phoneLink.onReceived(synced(sync.syncId, restarted))

        // then
        #expect(fixture.phoneLink.state.finishedRun?.result == confirmedResult)
    }

    @Test
    func `러닝 중엔 결과 닫기를 불러도 기억하지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(state(stateSequence: 1, statusVersion: 2))

        // when
        fixture.phoneLink.dismissResult()
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2, statusVersion: 2)))

        // then
        #expect(fixture.phoneLink.state.finishedRun?.result == confirmedResult)
    }

    @Test
    func `결과를 받는 중 13초 넘게 소식이 없으면 끊긴 것으로 보고 SYNC를 보낸다`() throws {
        // given
        let fixture = Fixture()
        fixture.phoneLink.onScreenVisibilityChanged(true)
        try fixture.connect(finishedState(stateSequence: 1, result: nil))

        // when -> 13초 직전까지는 끊긴 것으로 보지 않는다
        fixture.timer.advance(by: .milliseconds(12_900))

        // then
        #expect(fixture.phoneLink.state.isPhoneReachable)
        #expect(!fixture.sent.contains { $0.sync != nil })

        // when
        fixture.timer.advance(by: .milliseconds(200))

        // then
        #expect(!fixture.phoneLink.state.isPhoneReachable)
        #expect(fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `결과를 받는 중 켜짐 신호의 답이 오면 끊긴 것으로 보지 않는다`() throws {
        // given
        let fixture = Fixture()
        fixture.phoneLink.onScreenVisibilityChanged(true)
        try fixture.connect(finishedState(stateSequence: 1, result: nil))

        // when -> 10초 신호의 답을 받고 다시 12초가 지난다
        fixture.timer.advance(by: .seconds(10))
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2, result: nil)))
        fixture.timer.advance(by: .seconds(12))

        // then
        #expect(fixture.phoneLink.state.isPhoneReachable)
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `결과를 받으면 끊김 감시를 멈춘다`() throws {
        // given
        let fixture = Fixture()
        fixture.phoneLink.onScreenVisibilityChanged(true)
        try fixture.connect(finishedState(stateSequence: 1, result: nil))

        // when
        fixture.timer.advance(by: .seconds(5))
        fixture.phoneLink.onReceived(stateUpdated(finishedState(stateSequence: 2)))
        fixture.timer.advance(by: .seconds(60))

        // then
        #expect(fixture.phoneLink.state.isPhoneReachable)
        #expect(!fixture.sent.contains { $0.sync != nil })
    }

    @Test
    func `끊겼다고 본 뒤 SYNCED가 오면 결과를 받고 다시 연결된 것으로 본다`() throws {
        // given
        let fixture = Fixture()
        fixture.phoneLink.onScreenVisibilityChanged(true)
        try fixture.connect(finishedState(stateSequence: 1, result: nil))
        fixture.timer.advance(by: .milliseconds(13_100))
        let sync = try #require(fixture.sent.last { $0.sync != nil }?.sync)

        // when
        fixture.phoneLink.onReceived(synced(sync.syncId, finishedState(stateSequence: 2)))

        // then
        let linkState = fixture.phoneLink.state
        #expect(linkState.isPhoneReachable)
        #expect(linkState.finishedRun?.result == confirmedResult)
    }

    @Test
    func `화면이 꺼져 있으면 결과를 받는 중에도 끊김을 재지 않는다`() throws {
        // given
        let fixture = Fixture()
        try fixture.connect(finishedState(stateSequence: 1, result: nil))

        // when
        fixture.timer.advance(by: .seconds(60))

        // then
        #expect(fixture.phoneLink.state.isPhoneReachable)
        #expect(!fixture.sent.contains { $0.sync != nil })
    }
}

@MainActor
private final class Fixture {
    var sent: [WatchMessage] = []
    let timer = FakeTimer()
    private var nextId = 0

    lazy var phoneLink = PhoneLink(
        send: { [unowned self] in sent.append($0) },
        watchVersion: watchVersion,
        newId: { [unowned self] in
            nextId += 1
            return "id-\(nextId)"
        },
        schedule: timer.schedule
    )

    func connect(_ initial: PhoneState) throws {
        phoneLink.start()
        let sync = try #require(sent.last?.sync)
        phoneLink.onReceived(synced(sync.syncId, initial))
        sent.removeAll()
    }
}

// 기다리지 않고 맡긴 일을 시간 순서대로 그 자리에서 부른다
@MainActor
private final class FakeTimer {
    private struct Work {
        let id: Int
        let dueTime: Duration
        let action: @MainActor () -> Void
    }

    private var now = Duration.zero
    private var works: [Work] = []
    private var nextId = 0

    func schedule(after delay: Duration, _ action: @escaping @MainActor () -> Void) -> PhoneTimer {
        nextId += 1
        let id = nextId
        works.append(Work(id: id, dueTime: now + delay, action: action))
        return PhoneTimer { [weak self] in self?.works.removeAll { $0.id == id } }
    }

    // 부른 일이 새로 맡긴 일도 시간 안이면 이어서 부른다
    func advance(by duration: Duration) {
        let end = now + duration
        while let next = works.filter({ $0.dueTime <= end }).min(by: { ($0.dueTime, $0.id) < ($1.dueTime, $1.id) }) {
            works.removeAll { $0.id == next.id }
            now = next.dueTime
            next.action()
        }
        now = end
    }
}

extension WatchMessage {
    fileprivate var sync: WatchSync? {
        guard case .sync(let sync) = self else { return nil }
        return sync
    }

    fileprivate var pause: WatchPause? {
        guard case .pause(let pause) = self else { return nil }
        return pause
    }

    fileprivate var resume: WatchResume? {
        guard case .resume(let resume) = self else { return nil }
        return resume
    }

    fileprivate var finish: WatchFinish? {
        guard case .finish(let finish) = self else { return nil }
        return finish
    }

    fileprivate var isVisible: Bool? {
        guard case .visibilityUpdate(let visibilityUpdate) = self else { return nil }
        return visibilityUpdate.isVisible
    }
}

private let watchVersion = "1.0.0"

private let confirmedResult = RunResult(
    isServerConfirmed: true,
    totalDistanceMeters: 5020,
    averagePaceSecondsPerKm: 343,
    elapsedSeconds: 1721
)

private func synced(_ syncId: String, _ state: PhoneState) -> PhoneMessage {
    .synced(WatchSynced(syncId: syncId, state: state, birthday: nil, photos: []))
}

private func stateUpdated(_ state: PhoneState) -> PhoneMessage {
    .stateUpdated(WatchStateUpdated(state: state))
}

private func rejected(requestId: String, sourceType: String) -> PhoneMessage {
    .error(PhoneError(code: "STALE_STATUS", message: "다른 상태", sourceType: sourceType, requestId: requestId))
}

private func updateRequired(requestId: String?) -> PhoneMessage {
    .error(
        PhoneError(
            code: "WATCH_UPDATE_REQUIRED",
            message: "워치 앱 업데이트 필요",
            sourceType: "WATCH_SYNC",
            requestId: requestId
        )
    )
}

private func idleState(stateSequence: Int64) -> PhoneState {
    PhoneState(phoneInstanceId: "p1", stateSequence: stateSequence, statusVersion: 0, lastRequestId: nil, run: nil)
}

private func finishedState(
    stateSequence: Int64,
    statusVersion: Int = 0,
    phoneInstanceId: String = "p1",
    result: RunResult? = confirmedResult
) -> PhoneState {
    state(
        stateSequence: stateSequence,
        phoneInstanceId: phoneInstanceId,
        statusVersion: statusVersion,
        status: .finished,
        result: result
    )
}

private func state(
    stateSequence: Int64,
    phoneInstanceId: String = "p1",
    runningRoomId: Int64? = 812,
    statusVersion: Int = 0,
    lastRequestId: String? = nil,
    distanceMeters: Int = 1000,
    status: RunStatus = .running,
    result: RunResult? = nil
) -> PhoneState {
    PhoneState(
        phoneInstanceId: phoneInstanceId,
        stateSequence: stateSequence,
        statusVersion: statusVersion,
        lastRequestId: lastRequestId,
        run: RunState(
            runningRoomId: runningRoomId,
            type: .match,
            status: status,
            targetDistanceMeters: 5000,
            isServerConnected: true,
            isPenaltyApplicable: true,
            me: MyRecord(
                distanceMeters: distanceMeters,
                elapsedSeconds: 300,
                currentPaceSecondsPerKm: nil,
                caloriesKcal: nil,
                cadenceSpm: nil
            ),
            players: [],
            finish: nil,
            result: result
        )
    )
}
