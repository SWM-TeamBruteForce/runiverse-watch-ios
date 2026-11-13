import Foundation
import HealthKit
import OSLog

/// 기기의 운동 세션이다. 실패는 로그만 남기고 시작 못 함으로 알린다.
@MainActor
protocol WorkoutTracker: AnyObject {
    /// 못 재면 nil을 받는다.
    var onHeartRate: ((Int?) -> Void)? { get set }

    /// 끝내라고 하지 않았는데 세션이 끝났다 — 다른 앱이 운동을 시작했거나 오류다.
    var onEndedBySystem: (() -> Void)? { get set }

    /// 이미 답한 권한이면 창을 띄우지 않고 바로 부른다.
    func requestAuthorization(completion: @escaping () -> Void)

    /// 세션이 돌기 시작하면 true로 부른다.
    func start(configuration: HKWorkoutConfiguration, completion: @escaping (Bool) -> Void)

    /// 앱이 죽기 전 세션이 남아 있었으면 되찾아 true로 부른다.
    func recover(completion: @escaping (Bool) -> Void)

    /// 운동을 건강 앱에 저장하고 세션을 끝낸다. 저장이 실패해도 끝낸다.
    func end(completion: @escaping () -> Void)
}

/// HealthKit 운동 세션으로 손목을 내려도 앱을 살려 두고 심박을 받는다.
@MainActor
final class HealthKitWorkoutTracker: NSObject, WorkoutTracker {
    var onHeartRate: ((Int?) -> Void)?
    var onEndedBySystem: (() -> Void)?

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    // 시작·끝내기가 기다리는 중에 세션이 끝나면 스스로 끝난 것으로 알리지 않는다
    private var stateWaiter: StateWaiter?

    func requestAuthorization(completion: @escaping () -> Void) {
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: Self.shareTypes, read: Self.readTypes)
            } catch {
                Self.logger.warning("HealthKit 권한 요청 실패: \(error, privacy: .public)")
            }
            completion()
        }
    }

    func start(configuration: HKWorkoutConfiguration, completion: @escaping (Bool) -> Void) {
        let session: HKWorkoutSession
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        } catch {
            Self.logger.warning("운동 세션 만들기 실패: \(error, privacy: .public)")
            completion(false)
            return
        }
        attach(session)
        let startDate = Date()
        Task {
            let state = await waitForState(.running) { session.startActivity(with: startDate) }
            // 돌기 시작한 뒤에 기록을 시작해, 거절된 시작은 실패로 알린다
            guard state == .running else {
                detach()
                completion(false)
                return
            }
            do {
                try await builder?.beginCollection(at: startDate)
            } catch {
                // 세션만으로도 앱이 살아 있어 폰 메시지는 받는다 — 심박만 없다
                Self.logger.warning("운동 기록 시작 실패: \(error, privacy: .public)")
            }
            // 기록을 시작하는 사이 끝났으면 이미 떼어 냈으니 실패로 알린다
            completion(self.session === session)
        }
    }

    func recover(completion: @escaping (Bool) -> Void) {
        Task {
            let recovered: HKWorkoutSession?
            do {
                recovered = try await healthStore.recoverActiveWorkoutSession()
            } catch {
                Self.logger.warning("운동 세션 되찾기 실패: \(error, privacy: .public)")
                recovered = nil
            }
            guard let recovered, recovered.state != .ended else {
                completion(false)
                return
            }
            attach(recovered)
            completion(true)
        }
    }

    func end(completion: @escaping () -> Void) {
        guard let session else {
            completion()
            return
        }
        let builder = builder
        Task {
            if session.state == .running || session.state == .paused {
                _ = await waitForState(.stopped) { session.stopActivity(with: Date()) }
            }
            // 저장하는 사이 끝난 알림이 와도 스스로 끝난 것으로 보지 않게 먼저 뗀다
            detach()
            await Self.save(builder)
            session.end()
            completion()
        }
    }

    // 되찾은 세션도 대리자와 심박 받기를 다시 붙여야 한다
    private func attach(_ session: HKWorkoutSession) {
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: session.workoutConfiguration
        )
        session.delegate = self
        builder.delegate = self
        self.session = session
        self.builder = builder
    }

    private func detach() {
        session = nil
        builder = nil
    }

    // 끝나면(.ended) 기다리던 상태가 아니어도 돌려준다 — 끝난 세션은 더 바뀌지 않는다
    private func waitForState(
        _ target: HKWorkoutSessionState,
        after action: () -> Void
    ) async -> HKWorkoutSessionState {
        await withCheckedContinuation { continuation in
            stateWaiter = StateWaiter(target: target, continuation: continuation)
            action()
        }
    }

    private func onSessionStateChanged(_ changed: HKWorkoutSession, to state: HKWorkoutSessionState) {
        // 끝낸 세션의 늦은 알림은 버린다
        guard changed === session else { return }
        if let stateWaiter {
            guard state == stateWaiter.target || state == .ended else { return }
            self.stateWaiter = nil
            // 풀린 뒤 늦게 온 알림을 스스로 끝남으로 보지 않게, 돌지 않는 세션은 바로 뗀다
            if state != .running { detach() }
            stateWaiter.continuation.resume(returning: state)
            return
        }
        guard state == .ended else { return }
        // 끝난 세션도 그때까지 쌓인 운동은 저장한다
        let builder = builder
        detach()
        onEndedBySystem?()
        Task {
            await Self.save(builder)
            // 실패 알림만 오고 상태가 그대로면 세션이 아직 돌 수 있다
            changed.end()
        }
    }

    private func onHeartRateCollected(_ collecting: HKLiveWorkoutBuilder, heartRateBpm: Int?) {
        guard collecting === builder else { return }
        onHeartRate?(heartRateBpm)
    }

    private static func save(_ builder: HKLiveWorkoutBuilder?) async {
        guard let builder else { return }
        do {
            try await builder.endCollection(at: Date())
            _ = try await builder.finishWorkout()
        } catch {
            logger.warning("운동 저장 실패: \(error, privacy: .public)")
        }
    }

    // 운동만 쓰고 심박만 읽는다 — 칼로리·거리는 폰 값을 보여 준다
    private static let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
    private static let readTypes: Set<HKObjectType> = [HKQuantityType(.heartRate)]

    nonisolated private static let logger = Logger(subsystem: "RuniverseWatch", category: "WorkoutTracker")
}

extension HealthKitWorkoutTracker: HKWorkoutSessionDelegate {
    // 대리자는 메인이 아닌 직렬 큐에서 불린다 — 받은 순서 그대로 메인 큐에 넘긴다
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.onSessionStateChanged(workoutSession, to: toState) }
        }
    }

    // 세션을 멈추는 오류인데 상태가 바뀐다는 보장은 없어, 끝난 것으로 다룬다
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        Self.logger.warning("운동 세션 실패: \(error, privacy: .public)")
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.onSessionStateChanged(workoutSession, to: .ended) }
        }
    }
}

extension HealthKitWorkoutTracker: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let heartRateType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(heartRateType) else { return }
        let quantity = workoutBuilder.statistics(for: heartRateType)?.mostRecentQuantity()
        let heartRateBpm = quantity.map { Int($0.doubleValue(for: .count().unitDivided(by: .minute())).rounded()) }
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.onHeartRateCollected(workoutBuilder, heartRateBpm: heartRateBpm) }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

private struct StateWaiter {
    let target: HKWorkoutSessionState
    let continuation: CheckedContinuation<HKWorkoutSessionState, Never>
}
