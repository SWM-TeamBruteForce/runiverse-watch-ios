import SwiftUI

/// 워치 앱의 화면 전체를 담는다. 앱 타깃은 진입점에서 이것만 띄운다.
public struct RuniverseWatchScene: Scene {
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some Scene {
        WindowGroup {
            // TODO: 뼈대 확인용 글자 — 대기 화면을 만들 때 교체한다
            Text(verbatim: "Runiverse")
                .task {
                    // 폰 상태를 받기 전에 운동 세션이 지켜보게 먼저 만든다
                    let workoutSession = Self.workoutSession
                    Self.phoneLink.start()
                    // 러닝 화면에서 물으면 권한 창이 러닝을 가려, 화면이 처음 뜰 때 묻는다
                    workoutSession.requestAuthorization()
                }
        }
        // .active일 때만 화면이 켜진 것으로 본다 — 꺼지면 폰이 1초 전송을 멈춘다
        .onChange(of: scenePhase, initial: true) { _, phase in
            Self.phoneLink.onScreenVisibilityChanged(phase == .active)
        }
    }

    // 폰이 켠 운동은 화면이 아니라 앱 delegate로 온다
    static let workoutSession = WorkoutSession(phoneLink: phoneLink, tracker: HealthKitWorkoutTracker())

    // 화면이 닫혀도 연결을 이어 가려고 화면이 아니라 앱에 하나 둔다
    private static let phoneLink: PhoneLink = {
        let channel = PhoneChannel(
            onReceived: { phoneLink.onReceived($0) },
            onOpened: { phoneLink.onChannelOpened() }
        )
        let link = PhoneLink(send: channel.send)
        channel.activate()
        return link
    }()
}
