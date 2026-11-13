import Testing

@testable import RuniverseWatch

struct RunCommandsTests {

    @Test
    func `화면 거리가 목표에 못 미칠 때만 일찍 끝내는 종료다`() {
        // when & then -> 샘플 목표는 5000m다
        #expect(run(distanceMeters: 4999).isFinishForced)
        #expect(!run(distanceMeters: 5000).isFinishForced)
        #expect(!RunSamples.solo.isFinishForced)
    }

    private func run(distanceMeters: Int) -> RunState {
        let sample = RunSamples.party
        return RunState(
            runningRoomId: sample.runningRoomId,
            type: sample.type,
            status: sample.status,
            targetDistanceMeters: sample.targetDistanceMeters,
            isServerConnected: sample.isServerConnected,
            isPenaltyApplicable: sample.isPenaltyApplicable,
            me: MyRecord(
                distanceMeters: distanceMeters,
                elapsedSeconds: sample.me.elapsedSeconds,
                currentPaceSecondsPerKm: sample.me.currentPaceSecondsPerKm,
                caloriesKcal: sample.me.caloriesKcal,
                cadenceSpm: sample.me.cadenceSpm
            ),
            players: sample.players,
            finish: nil,
            result: nil
        )
    }
}
