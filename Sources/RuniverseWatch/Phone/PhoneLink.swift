import Foundation
import Observation

/// 끝난 결과를 가리키는 번호 쌍이다 — 오프라인 솔로는 방 번호가 끝까지 없어 방 번호로 못 가린다.
struct ResultKey: Equatable {
    let phoneInstanceId: String
    let statusVersion: Int
}

struct PhoneLinkState: Equatable {
    /// 연결이 끊겨도 러닝을 접기 전까지 지우지 않는다 — 화면은 이 값에서 멈춘다.
    var phoneState: PhoneState?
    var birthday: String?
    var photos: [PlayerPhoto] = []
    /// false면 `폰 연결 확인 중`을 띄운다.
    var isPhoneReachable = true
    /// SYNC를 보내고 SYNCED를 기다리는 중이다.
    var isSyncing = false
    /// 보내고 아직 결과를 못 받은 명령이다.
    var pendingRequestId: String?
    /// 보내고 아직 결과를 못 받은 명령이 종료다.
    var isFinishPending = false
    /// 명령을 보낸 지 3초가 넘었다 — 종료면 `종료 확인 중`을 띄운다.
    var isCommandOverdue = false
    /// 워치에서 닫은 결과다. 같은 결과를 다시 받아도 띄우지 않는다.
    var dismissedResult: ResultKey?
    /// 폰이 이 워치 버전을 거절했다 — 앱을 다시 열 때까지 폰에 새로 보내지 않는다.
    var isUpdateRequired = false
    /// 러닝이 있을 것으로 보는데 그 뒤 폰 상태를 아직 못 받았다.
    var isAwaitingRun = false

    var isLocked: Bool { isSyncing || pendingRequestId != nil }

    /// 마지막으로 받은 상태에 아직 끝나지 않은 러닝이 있다.
    var isRunActive: Bool {
        guard let run = phoneState?.run else { return false }
        return run.status != .finished
    }

    /// 결과 화면에 띄울 끝난 러닝이다.
    var finishedRun: RunState? {
        guard let phoneState, let run = phoneState.run, run.status == .finished else { return nil }
        return phoneState.resultKey == dismissedResult ? nil : run
    }
}

extension PhoneState {
    fileprivate var resultKey: ResultKey { ResultKey(phoneInstanceId: phoneInstanceId, statusVersion: statusVersion) }
}

/// 맡겨 둔 일이다. 시간이 되기 전에 `cancel()`하면 부르지 않는다.
struct PhoneTimer {
    let cancel: @MainActor () -> Void
}

/// 시간이 지난 뒤 할 일을 맡긴다.
typealias PhoneSchedule = @MainActor (Duration, @escaping @MainActor () -> Void) -> PhoneTimer

/// 폰에서 받은 메시지로 연결 상태를 판정하고, 명령·SYNC·화면 켜짐 신호를 보낸다.
@MainActor
@Observable
final class PhoneLink {
    private(set) var state = PhoneLinkState() {
        didSet { onStateChanged?(state) }
    }

    /// 콤보 순간을 받는 곳이다. 비어 있으면 버린다 — 지난 콤보를 뒤늦게 울리지 않는다.
    @ObservationIgnored var onCombo: ((WatchComboTriggered) -> Void)?

    /// 상태가 바뀔 때마다 부른다. 바꾸는 도중이라 여기서 PhoneLink를 다시 부르지 않는다.
    @ObservationIgnored var onStateChanged: ((PhoneLinkState) -> Void)?

    private let send: (WatchMessage) -> Void
    private let watchVersion: String
    private let newId: () -> String
    private let schedule: PhoneSchedule

    @ObservationIgnored private var awaitedSyncIds: [String] = []
    @ObservationIgnored private var seenComboEventIds: [String] = []
    @ObservationIgnored private var isScreenVisible = false
    @ObservationIgnored private var syncTimer: PhoneTimer?
    @ObservationIgnored private var silenceTimer: PhoneTimer?
    @ObservationIgnored private var commandTimer: PhoneTimer?
    @ObservationIgnored private var visibilityTimer: PhoneTimer?

    /// `schedule`은 테스트가 시간을 직접 흘리려고 바꿔 끼운다.
    init(
        send: @escaping (WatchMessage) -> Void,
        watchVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
        newId: @escaping () -> String = { UUID().uuidString },
        schedule: @escaping PhoneSchedule = PhoneLink.sleepThenRun
    ) {
        self.send = send
        self.watchVersion = watchVersion
        self.newId = newId
        self.schedule = schedule
    }

    /// 화면을 새로 만들 때 부른다 — 닫혀 있던 동안의 상태를 SYNC로 새로 맞춘다.
    func start() {
        if state.isUpdateRequired {
            state = PhoneLinkState()
            // 거절할 때 멈춘 켜짐 신호를 화면이 켜진 채 다시 열면 여기서 다시 켠다
            if isScreenVisible { applyScreenVisibility() }
        }
        requestSync()
    }

    /// 화면이 꺼진 동안 폰이 있는지 묻는다. 켜져 있으면 3초 감시가 이미 묻고 있다.
    func probeWhileScreenOff() {
        if !isScreenVisible { requestSync() }
    }

    /// 폰이 돌아오지 않아 러닝을 접는다. 다음 SYNCED 전까지 상태를 받지 않는다.
    func forgetRun() {
        syncTimer?.cancel()
        silenceTimer?.cancel()
        commandTimer?.cancel()
        // 접기 전에 보낸 물음의 답이 늦게 와도 접은 러닝을 되살리지 않는다
        awaitedSyncIds.removeAll()
        state = PhoneLinkState()
    }

    /// 폰이 러닝을 시작하며 워치 앱을 켰거나, 러닝 중에 죽은 앱이 다시 떴다. 폰 상태를 받으면 풀린다.
    func onRunExpected() {
        // 폰이 이 버전을 거절해 이 러닝을 받을 수 없다
        guard !state.isUpdateRequired else { return }
        state.isAwaitingRun = true
        // 3초 감시가 꺼져 있을 수 있고 폰은 켜짐 신호 전엔 화면이 꺼진 줄 알아, 화면이 켜질 때처럼 다시 건다
        if isScreenVisible { applyScreenVisibility() }
        // 이어 받을 상태가 없으면 폰이 보내는 상태를 버려, SYNC로 새로 받는다
        if state.phoneState == nil, !state.isSyncing { requestSync() }
    }

    /// 폰에 알리지 않고 번호 쌍만 기억한다. 끝난 러닝이 아니면 할 일이 없다.
    func dismissResult() {
        guard let phoneState = state.phoneState, phoneState.run?.status == .finished else { return }
        state.dismissedResult = phoneState.resultKey
    }

    /// 통로가 열릴 때마다 부른다 — 열리기 전에 보낸 SYNC·켜짐 신호는 버려졌다.
    func onChannelOpened() {
        if state.isSyncing { requestSync() }
        if isScreenVisible, !state.isUpdateRequired {
            visibilityTimer?.cancel()
            sendVisibleSignal()
        }
    }

    func onScreenVisibilityChanged(_ isVisible: Bool) {
        guard isVisible != isScreenVisible else { return }
        isScreenVisible = isVisible
        applyScreenVisibility()
    }

    func onReceived(_ message: PhoneMessage) {
        switch message {
        case .synced(let synced): onSynced(synced)
        case .stateUpdated(let stateUpdated): onStateUpdated(stateUpdated.state)
        case .comboTriggered(let combo): onComboTriggered(combo)
        case .error(let error): onError(error)
        }
    }

    /// 잠겨 있거나 러닝이 없으면 보내지 않고 false를 돌려준다. 아래 셋 모두 같다.
    func pause() -> Bool {
        sendCommand(isFinish: false) {
            .pause(WatchPause(requestId: $0, phoneInstanceId: $1, runningRoomId: $2, statusVersion: $3))
        }
    }

    func resume() -> Bool {
        sendCommand(isFinish: false) {
            .resume(WatchResume(requestId: $0, phoneInstanceId: $1, runningRoomId: $2, statusVersion: $3))
        }
    }

    func finish(forced: Bool) -> Bool {
        sendCommand(isFinish: true) {
            .finish(
                WatchFinish(requestId: $0, phoneInstanceId: $1, runningRoomId: $2, statusVersion: $3, forced: forced)
            )
        }
    }

    private func applyScreenVisibility() {
        visibilityTimer?.cancel()
        // 켜질 때마다 3초 감시가 SYNC를 다시 보내 거절을 되풀이하지 않게 한다
        if state.isUpdateRequired { return }
        if isScreenVisible {
            sendVisibleSignal()
            if state.isSyncing { requestSync() } else { awaitVisibleReply() }
        } else {
            send(.visibilityUpdate(WatchVisibilityUpdate(isVisible: false)))
            silenceTimer?.cancel()
        }
    }

    private func sendVisibleSignal() {
        send(.visibilityUpdate(WatchVisibilityUpdate(isVisible: true)))
        visibilityTimer = schedule(Self.visibilityInterval) { [weak self] in self?.sendVisibleSignal() }
    }

    private func sendCommand(
        isFinish: Bool,
        build: (_ requestId: String, _ phoneInstanceId: String, _ runningRoomId: Int64?, _ statusVersion: Int) ->
            WatchMessage
    ) -> Bool {
        guard let phoneState = state.phoneState, let run = phoneState.run, !state.isLocked else { return false }

        let requestId = newId()
        state.pendingRequestId = requestId
        state.isFinishPending = isFinish
        state.isCommandOverdue = false
        send(build(requestId, phoneState.phoneInstanceId, run.runningRoomId, phoneState.statusVersion))
        commandTimer?.cancel()
        // 명령은 다시 보내지 않는다 — 폰이 이미 처리했을 수 있어, 최신 상태부터 받아 본다
        commandTimer = schedule(Self.replyTimeout) { [weak self] in
            guard let self else { return }
            state.isCommandOverdue = true
            requestSync()
        }
        return true
    }

    private func requestSync() {
        state.isSyncing = true
        silenceTimer?.cancel()
        syncTimer?.cancel()
        sendSync()
    }

    // 화면이 꺼져 있으면 한 번만 보내고, 켜질 때 다시 시작한다
    private func sendSync() {
        let syncId = newId()
        awaitedSyncIds.append(capped: syncId, limit: Self.syncIdMemoryCount)
        send(.sync(WatchSync(syncId: syncId, watchVersion: watchVersion)))
        syncTimer = schedule(Self.replyTimeout) { [weak self] in
            guard let self else { return }
            state.isPhoneReachable = false
            if isScreenVisible { sendSync() }
        }
    }

    private func onSynced(_ synced: WatchSynced) {
        guard awaitedSyncIds.contains(synced.syncId) else { return }
        awaitedSyncIds.removeAll()
        syncTimer?.cancel()
        commandTimer?.cancel()
        state = PhoneLinkState(
            phoneState: synced.state,
            birthday: synced.birthday,
            photos: synced.photos,
            dismissedResult: state.dismissedResult
        )
        awaitNextState()
    }

    private func onStateUpdated(_ incoming: PhoneState) {
        // SYNC 중엔 사진·번호를 새로 받기 전이라 이어 붙이지 않는다
        guard !state.isSyncing, let known = state.phoneState else { return }
        if incoming.phoneInstanceId != known.phoneInstanceId {
            requestSync()
            return
        }
        guard incoming.stateSequence > known.stateSequence else { return }
        if let incomingRoomId = incoming.run?.runningRoomId, incomingRoomId != known.run?.runningRoomId {
            requestSync()
            return
        }

        state.phoneState = incoming
        state.isAwaitingRun = false
        if let pendingRequestId = state.pendingRequestId, incoming.lastRequestId == pendingRequestId {
            commandTimer?.cancel()
            state.pendingRequestId = nil
            state.isFinishPending = false
            state.isCommandOverdue = false
        }
        awaitNextState()
    }

    private func onComboTriggered(_ combo: WatchComboTriggered) {
        guard !seenComboEventIds.contains(combo.eventId) else { return }
        seenComboEventIds.append(capped: combo.eventId, limit: Self.comboEventIdMemoryCount)
        onCombo?(combo)
    }

    private func onError(_ error: PhoneError) {
        // 어느 SYNC의 거절이든 버전은 같아 번호를 맞춰 보지 않는다
        if error.code == "WATCH_UPDATE_REQUIRED" {
            requireUpdate()
            return
        }
        guard let requestId = error.requestId, requestId == state.pendingRequestId else { return }
        commandTimer?.cancel()
        state.pendingRequestId = nil
        state.isFinishPending = false
        state.isCommandOverdue = false
    }

    // 러닝을 비워 운동 세션도 끝난다 — 폰 기록은 폰에서 계속된다
    private func requireUpdate() {
        syncTimer?.cancel()
        silenceTimer?.cancel()
        commandTimer?.cancel()
        visibilityTimer?.cancel()
        awaitedSyncIds.removeAll()
        state = PhoneLinkState(isUpdateRequired: true)
    }

    // 폰은 켜짐 신호를 받으면 러닝이 없어도 바로 답한다 — 답이 없으면 끊긴 것이다
    private func awaitVisibleReply() {
        silenceTimer?.cancel()
        silenceTimer = schedule(Self.replyTimeout) { [weak self] in self?.onSilence() }
    }

    // 폰은 화면이 켜져 있고 러닝이 끝나기 전에만 이어서 보낸다 — 받은 결과 뒤엔 조용한 게 정상이다
    private func awaitNextState() {
        silenceTimer?.cancel()
        guard isScreenVisible, let run = state.phoneState?.run else { return }
        let timeout: Duration
        if run.status != .finished {
            timeout = Self.replyTimeout
        } else if run.result == nil {
            timeout = Self.resultReplyTimeout
        } else {
            return
        }
        silenceTimer = schedule(timeout) { [weak self] in self?.onSilence() }
    }

    private func onSilence() {
        state.isPhoneReachable = false
        requestSync()
    }

    private static let replyTimeout = Duration.seconds(3)
    private static let visibilityInterval = Duration.seconds(10)

    // 끝난 뒤 폰은 켜짐 신호에만 답해, 3초로 재면 폰이 멀쩡해도 끊긴 것으로 본다
    private static let resultReplyTimeout = visibilityInterval + replyTimeout

    // 늦게 온 SYNCED도 받되, 화면을 켜 둔 채 폰이 사라져도 끝없이 쌓이지 않게 한다
    private static let syncIdMemoryCount = 5
    private static let comboEventIdMemoryCount = 64
}

extension PhoneLink {
    /// 실제 시간으로 기다렸다 부른다.
    static func sleepThenRun(after delay: Duration, _ action: @escaping @MainActor () -> Void) -> PhoneTimer {
        let task = Task { @MainActor in
            try? await Task.sleep(for: delay)
            // 잠이 끝난 뒤 이 작업이 차례를 기다리는 사이에 취소될 수 있다
            guard !Task.isCancelled else { return }
            action()
        }
        return PhoneTimer { task.cancel() }
    }
}

extension Array where Element == String {
    fileprivate mutating func append(capped element: String, limit: Int) {
        append(element)
        if count > limit { removeFirst() }
    }
}
