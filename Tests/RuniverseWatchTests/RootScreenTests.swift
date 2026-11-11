import Testing

@testable import RuniverseWatch

struct RootScreenTests {

    @Test
    func `끝나지 않은 러닝이 있으면 러닝 화면이다`() {
        // given
        let linkState = PhoneLinkState(phoneState: state(status: .paused), isPhoneReachable: false)

        // when & then
        #expect(RootScreen(linkState) == .run(run(status: .paused)))
    }

    @Test
    func `폰이 버전을 거절했으면 업데이트 필요 화면이다`() {
        // when & then
        #expect(RootScreen(PhoneLinkState(isUpdateRequired: true)) == .updateRequired)
    }

    @Test
    func `끝난 러닝은 결과 요약이고 워치에서 닫았으면 대기 화면이다`() {
        // given
        let finished = PhoneLinkState(phoneState: state(status: .finished))
        let dismissed = PhoneLinkState(
            phoneState: state(status: .finished),
            dismissedResult: ResultKey(phoneInstanceId: "p1", statusVersion: 0)
        )

        // when & then
        #expect(RootScreen(finished) == .runSummary(run(status: .finished)))
        #expect(RootScreen(dismissed) == .idle(isPhoneReachable: true))
    }

    @Test
    func `러닝이 없으면 대기 화면이고 폰 연결 상태를 넘긴다`() {
        // given
        let idle = PhoneState(phoneInstanceId: "p1", stateSequence: 1, statusVersion: 0, lastRequestId: nil, run: nil)

        // when & then
        #expect(RootScreen(PhoneLinkState(phoneState: idle)) == .idle(isPhoneReachable: true))
        #expect(RootScreen(PhoneLinkState(isPhoneReachable: false)) == .idle(isPhoneReachable: false))
    }
}

private func state(status: RunStatus) -> PhoneState {
    PhoneState(phoneInstanceId: "p1", stateSequence: 1, statusVersion: 0, lastRequestId: nil, run: run(status: status))
}

private func run(status: RunStatus) -> RunState {
    RunState(
        runningRoomId: 812,
        type: .solo,
        status: status,
        targetDistanceMeters: nil,
        isServerConnected: true,
        isPenaltyApplicable: false,
        me: MyRecord(
            distanceMeters: 1000,
            elapsedSeconds: 300,
            currentPaceSecondsPerKm: nil,
            caloriesKcal: nil,
            cadenceSpm: nil
        ),
        players: [],
        finish: nil,
        result: nil
    )
}
