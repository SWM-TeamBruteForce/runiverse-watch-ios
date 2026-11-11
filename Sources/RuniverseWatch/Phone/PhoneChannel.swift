import Foundation
import OSLog
import WatchConnectivity

/// WatchConnectivity로 폰과 메시지를 주고받는다.
final class PhoneChannel: NSObject, WCSessionDelegate {
    private let session = WCSession.default
    private let onReceived: @MainActor (PhoneMessage) -> Void
    private let onOpened: @MainActor () -> Void

    init(
        onReceived: @escaping @MainActor (PhoneMessage) -> Void,
        onOpened: @escaping @MainActor () -> Void
    ) {
        self.onReceived = onReceived
        self.onOpened = onOpened
        super.init()
    }

    /// 받기를 시작한다. 활성화가 끝나고 폰에 닿을 때마다 `onOpened`를 부른다.
    func activate() {
        session.delegate = self
        session.activate()
    }

    // 실패를 되묻지 않는다 — 답이 안 오면 PhoneLink가 SYNC로 다시 맞춘다
    func send(_ message: WatchMessage) {
        // 활성화 전에 보내면 프로그래머 오류다
        guard session.activationState == .activated else {
            Self.logger.debug("세션 활성화 전 — \(message.event, privacy: .public) 안 보냄")
            return
        }
        let body: Data
        do {
            body = try PhoneMessageCodec.encode(message)
        } catch {
            Self.logger.error("폰 메시지 쓰기 실패 — \(message.event, privacy: .public): \(error, privacy: .public)")
            return
        }
        let event = message.event
        session.sendMessageData(body, replyHandler: nil) { error in
            Self.logger.warning("폰으로 보내기 실패 — \(event, privacy: .public): \(error, privacy: .public)")
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            Self.logger.error("세션 활성화 실패: \(error, privacy: .public)")
            return
        }
        // 활성화 직후엔 아직 안 닿을 수 있다 — 그땐 닿는 순간 부른다
        guard activationState == .activated, session.isReachable else { return }
        notifyOpened()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.activationState == .activated, session.isReachable else { return }
        notifyOpened()
    }

    private func notifyOpened() {
        let onOpened = onOpened
        DispatchQueue.main.async {
            MainActor.assumeIsolated { onOpened() }
        }
    }

    // 깨진 메시지 하나로 받기를 멈추지 않는다 — 다음 상태가 곧 다시 온다
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        let message: PhoneMessage?
        do {
            message = try PhoneMessageCodec.decode(messageData)
        } catch {
            Self.logger.warning("폰 메시지 해석 실패: \(error, privacy: .public)")
            return
        }
        guard let message else { return }
        Self.logger.debug("받음 — \(message.event, privacy: .public)")
        let onReceived = onReceived
        // 대리자는 메인이 아닌 직렬 큐에서 불린다 — 받은 순서 그대로 메인 큐에 넘긴다
        DispatchQueue.main.async {
            MainActor.assumeIsolated { onReceived(message) }
        }
    }

    private static let logger = Logger(subsystem: "RuniverseWatch", category: "PhoneChannel")
}

extension PhoneMessage {
    /// 로그에 남기는 이름이다. 값은 남기지 않는다.
    fileprivate var event: String {
        switch self {
        case .synced: "WATCH_SYNCED"
        case .stateUpdated: "WATCH_STATE_UPDATED"
        case .comboTriggered: "WATCH_COMBO_TRIGGERED"
        case .error: "ERROR"
        }
    }
}
