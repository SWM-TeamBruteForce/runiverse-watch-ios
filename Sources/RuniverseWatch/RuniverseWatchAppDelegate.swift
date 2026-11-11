import HealthKit
import WatchKit

/// 폰이 켠 운동과 앱이 죽기 전 남은 운동을 받는다.
/// 앱 타깃이 `@WKApplicationDelegateAdaptor`로 단다.
public final class RuniverseWatchAppDelegate: NSObject, WKApplicationDelegate {
    public func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        RuniverseWatchScene.workoutSession.onLaunchedByPhone(workoutConfiguration)
    }

    public func handleActiveWorkoutRecovery() {
        RuniverseWatchScene.workoutSession.onRecoveryRequested()
    }
}
