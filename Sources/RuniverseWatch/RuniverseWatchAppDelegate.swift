import HealthKit
import WatchKit

/// 폰이 켠 운동과 앱이 죽기 전 남은 운동을 받는다.
/// 앱 타깃이 `@WKApplicationDelegateAdaptor`로 단다.
public final class RuniverseWatchAppDelegate: NSObject, WKApplicationDelegate {
    public func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        RuniverseWatchScene.phoneLink.onRunExpected()
        RuniverseWatchScene.workoutSession.onLaunchedByPhone(workoutConfiguration)
    }

    public func handleActiveWorkoutRecovery() {
        // 러닝 중에 죽었다 다시 뜬 앱이라, 폰 답 전에 `폰에서 러닝 시작`이 끼지 않게 기다린다
        RuniverseWatchScene.phoneLink.onRunExpected()
        RuniverseWatchScene.workoutSession.onRecoveryRequested()
    }
}
