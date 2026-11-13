import SwiftUI
import WatchKit

/// 워치 앱의 화면 전체를 담는다. 앱 타깃은 진입점에서 이것만 띄운다.
public struct RuniverseWatchScene: Scene {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            RootView(phoneLink: Self.phoneLink, workoutSession: Self.workoutSession, comboMoments: Self.comboMoments)
                .task {
                    // 폰 상태를 받기 전에 운동 세션이 지켜보게 먼저 만든다
                    let workoutSession = Self.workoutSession
                    Self.phoneLink.start()
                    // 러닝 화면에서 물으면 권한 창이 러닝을 가려, 화면이 처음 뜰 때 묻는다
                    workoutSession.requestAuthorization()
                }
        }
    }

    // 폰이 켠 운동은 화면이 아니라 앱 delegate로 온다
    static let workoutSession = WorkoutSession(phoneLink: phoneLink, tracker: HealthKitWorkoutTracker())

    // 화면이 닫혀도 연결을 이어 가려고 화면이 아니라 앱에 하나 둔다
    static let phoneLink: PhoneLink = {
        let link = openPhoneLink()
        // 워치 진동엔 소리가 붙어 무음 모드가 아니면 콤보마다 울려, 콤보는 진동 없이 효과만 띄운다
        link.onCombo = { comboMoments.onCombo($0, linkState: phoneLink.state) }
        // 화면이 꺼져 있어도 울리게 보류 진동은 화면이 아니라 앱에서 받는다
        link.onGoalPending = { WKInterfaceDevice.current().play(.notification) }
        return link
    }()

    static let comboMoments = ComboMoments()

    private static func openPhoneLink() -> PhoneLink {
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
    }
}

/// 폰 상태는 여기서만 읽고, 아래 화면엔 값만 넘긴다.
private struct RootView: View {
    let phoneLink: PhoneLink
    let workoutSession: WorkoutSession
    let comboMoments: ComboMoments

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    @State private var playerPhotos: [String: CGImage] = [:]

    var body: some View {
        screen
            // 앱으로 돌아올 때도 .inactive를 잠깐 거쳐, .inactive로 꺼진 것은 이어질 때만 알린다
            .task(id: ScreenVisibilityTrigger(scenePhase: scenePhase, isLuminanceReduced: isLuminanceReduced)) {
                if !isScreenVisible, scenePhase == .inactive {
                    try? await Task.sleep(for: Self.screenOffDelay)
                    guard !Task.isCancelled else { return }
                }
                phoneLink.onScreenVisibilityChanged(isScreenVisible)
            }
            // 어두워진 화면은 시스템이 그리기를 줄여 애니메이션이 안 보여, 콤보 효과는 밝은 화면에서만 띄운다
            // 위 2초 대기와 따로 둬야 꺼지자마자 콤보를 버린다
            .onChange(of: scenePhase, initial: true) { _, phase in
                comboMoments.onScreenActiveChanged(phase == .active)
            }
            // 1초마다 오는 상태로는 다시 풀지 않게 사진이 바뀔 때만 푼다
            .onChange(of: phoneLink.state.photos, initial: true) { _, photos in
                playerPhotos = PlayerPhotos.decode(photos)
            }
    }

    // 어두워진 화면과 꺼진 화면(항상 켬 꺼짐·저전력 모드)이 모두 .inactive라, 어두워진 화면에서만 켜지는 밝기 줄임으로 가른다
    private var isScreenVisible: Bool {
        switch scenePhase {
        case .active: true
        case .inactive: isLuminanceReduced
        default: false
        }
    }

    // 앱으로 돌아올 때 .inactive를 거치는 시간(실측 0.3~0.6초)보다 넉넉히 잡은 값이다
    private static let screenOffDelay = Duration.seconds(2)

    @ViewBuilder
    private var screen: some View {
        switch RootScreen(phoneLink.state) {
        case .run(let run):
            let linkState = phoneLink.state
            RunView(
                run: run,
                isPhoneReachable: linkState.isPhoneReachable,
                heartRateBpm: workoutSession.heartRateBpm,
                birthday: linkState.birthday,
                commandState: RunCommandState(
                    isLocked: linkState.isLocked,
                    isFinishPending: linkState.isFinishPending,
                    isCommandOverdue: linkState.isCommandOverdue
                ),
                // 잠겨 있으면 PhoneLink가 보내지 않고 false를 돌려줘, 버튼은 결과를 따로 보지 않는다
                // 길게 누르는 동안 거리가 목표를 넘을 수 있어 일찍 끝내는지는 보내는 순간에 정한다
                commands: RunCommands(
                    pause: { _ = phoneLink.pause() },
                    resume: { _ = phoneLink.resume() },
                    finish: { _ = phoneLink.finish(forced: phoneLink.state.phoneState?.run?.isFinishForced ?? false) }
                ),
                playerPhotos: playerPhotos,
                smallComboMoments: comboMoments.smallMoments,
                comboBurst: comboMoments.burst,
                onControlsShownChanged: { comboMoments.onControlsShownChanged($0) }
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

private struct ScreenVisibilityTrigger: Hashable {
    let scenePhase: ScenePhase
    let isLuminanceReduced: Bool
}
