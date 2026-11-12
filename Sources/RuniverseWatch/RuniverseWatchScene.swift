import SwiftUI

/// 워치 앱의 화면 전체를 담는다. 앱 타깃은 진입점에서 이것만 띄운다.
public struct RuniverseWatchScene: Scene {
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some Scene {
        WindowGroup {
            RootView(phoneLink: Self.phoneLink, workoutSession: Self.workoutSession)
                .task {
                    // 폰 상태를 받기 전에 운동 세션이 지켜보게 먼저 만든다
                    let workoutSession = Self.workoutSession
                    Self.phoneLink.start()
                    // 러닝 화면에서 물으면 권한 창이 러닝을 가려, 화면이 처음 뜰 때 묻는다
                    workoutSession.requestAuthorization()
                }
        }
        // 어두워진 화면(.inactive)에도 값이 떠 있어 .background일 때만 1초 전송을 멈춘다
        .onChange(of: scenePhase, initial: true) { _, phase in
            Self.phoneLink.onScreenVisibilityChanged(phase != .background)
        }
    }

    // 폰이 켠 운동은 화면이 아니라 앱 delegate로 온다
    static let workoutSession = WorkoutSession(phoneLink: phoneLink, tracker: HealthKitWorkoutTracker())

    // 화면이 닫혀도 연결을 이어 가려고 화면이 아니라 앱에 하나 둔다
    static let phoneLink: PhoneLink = {
        #if DEBUG
            // 실행 인자 `-fakeRun <경우>`는 UserDefaults 인자 영역으로 읽힌다
            if let fakePhone = FakePhone(fakeRunName: UserDefaults.standard.string(forKey: "fakeRun")) {
                let link = PhoneLink(send: { fakePhone.send($0) })
                fakePhone.start(onReceived: { link.onReceived($0) }, onOpened: { link.onChannelOpened() })
                return link
            }
        #endif
        let channel = PhoneChannel(
            onReceived: { phoneLink.onReceived($0) },
            onOpened: { phoneLink.onChannelOpened() }
        )
        let link = PhoneLink(send: channel.send)
        channel.activate()
        return link
    }()
}

/// 폰 상태는 여기서만 읽고, 아래 화면엔 값만 넘긴다.
private struct RootView: View {
    let phoneLink: PhoneLink
    let workoutSession: WorkoutSession

    var body: some View {
        switch RootScreen(phoneLink.state) {
        case .run(let run):
            RunView(
                run: run,
                isPhoneReachable: phoneLink.state.isPhoneReachable,
                heartRateBpm: workoutSession.heartRateBpm,
                birthday: phoneLink.state.birthday
            )
        case .updateRequired:
            UpdateRequiredView()
        case .runSummary:
            // TODO: 결과 요약 — 결과 요약을 만들 때 교체한다
            Text(verbatim: "러닝 완료")
        case .awaitingPhone:
            IdleView(content: nil)
        case .idle(let isPhoneReachable):
            IdleView(content: IdleContent(isPhoneReachable: isPhoneReachable))
        }
    }
}
