import Testing
import WatchKit

@testable import RuniverseWatch

@MainActor
struct RunVibrationTests {

    @Test
    func `1 오름과 끊김은 서로 다른 진동으로 한 번 울린다`() {
        // given
        let fixture = Fixture()

        // when
        fixture.vibrator.vibrate(.combo(.tick, headcount: 2))
        fixture.timer.advance(by: .seconds(1))
        fixture.vibrator.vibrate(.combo(.break, headcount: 2))
        fixture.timer.advance(by: .seconds(1))

        // then
        #expect(
            fixture.played == [
                Played(haptic: .directionUp, at: .zero),
                Played(haptic: .directionDown, at: .seconds(1)),
            ]
        )
    }

    @Test
    func `큰 순간은 1 오름 진동을 두 번 울리고 넷부터는 세 번 울린다`() {
        // given
        let fixture = Fixture()

        // when -> 나까지 셋
        fixture.vibrator.vibrate(.combo(.milestone, headcount: 3))
        fixture.timer.advance(by: .seconds(1))

        // then
        #expect(
            fixture.played == [
                Played(haptic: .directionUp, at: .zero),
                Played(haptic: .directionUp, at: .milliseconds(210)),
            ]
        )

        // when -> 나까지 넷
        fixture.played.removeAll()
        fixture.vibrator.vibrate(.combo(.milestone, headcount: 4))
        fixture.timer.advance(by: .seconds(1))

        // then
        #expect(
            fixture.played == [
                Played(haptic: .directionUp, at: .seconds(1)),
                Played(haptic: .directionUp, at: .milliseconds(1210)),
                Played(haptic: .directionUp, at: .milliseconds(1420)),
            ]
        )
    }

    @Test
    func `보류는 알림 진동으로 한 번 울린다`() {
        // given
        let fixture = Fixture()

        // when
        fixture.vibrator.vibrate(.goalPending)
        fixture.timer.advance(by: .seconds(1))

        // then
        #expect(fixture.played == [Played(haptic: .notification, at: .zero)])
    }

    @Test
    func `울리는 중엔 같거나 덜 급한 진동을 버린다`() {
        // given -> 끊김은 0.18초 울린다
        let fixture = Fixture()
        fixture.vibrator.vibrate(.combo(.break, headcount: 2))

        // when
        fixture.timer.advance(by: .milliseconds(100))
        fixture.vibrator.vibrate(.combo(.tick, headcount: 2))
        fixture.vibrator.vibrate(.combo(.break, headcount: 2))

        // then
        #expect(fixture.played == [Played(haptic: .directionDown, at: .zero)])
    }

    @Test
    func `다 울린 뒤엔 덜 급한 진동도 울린다`() {
        // given
        let fixture = Fixture()
        fixture.vibrator.vibrate(.combo(.break, headcount: 2))

        // when
        fixture.timer.advance(by: .milliseconds(180))
        fixture.vibrator.vibrate(.combo(.tick, headcount: 2))

        // then
        #expect(
            fixture.played == [
                Played(haptic: .directionDown, at: .zero),
                Played(haptic: .directionUp, at: .milliseconds(180)),
            ]
        )
    }

    @Test
    func `더 급한 진동이 끼면 큰 순간의 남은 되풀이를 멈춘다`() {
        // given
        let fixture = Fixture()
        fixture.vibrator.vibrate(.combo(.milestone, headcount: 3))

        // when
        fixture.timer.advance(by: .milliseconds(100))
        fixture.vibrator.vibrate(.goalPending)
        fixture.timer.advance(by: .seconds(1))

        // then
        #expect(
            fixture.played == [
                Played(haptic: .directionUp, at: .zero),
                Played(haptic: .notification, at: .milliseconds(100)),
            ]
        )
    }

    @Test
    func `콤보 인원은 콤보 중인 사람과 지금 순간의 사람에 나를 더한다`() {
        // given -> 샘플은 콩나물(u2)만 콤보 중이다
        let players = RunSamples.party.players

        // when & then
        #expect(RunVibration.comboHeadcount(players: players, comboUserId: "u1") == 3)
        #expect(RunVibration.comboHeadcount(players: players, comboUserId: "u2") == 2)
    }

    @Test
    func `러닝 중에 온 콤보만 울린다`() {
        // given
        let fixture = Fixture()
        let combo = WatchComboTriggered(eventId: "e1", userId: "u2", comboCount: 13, kind: .tick)

        // when
        fixture.vibrator.onCombo(combo, linkState: PhoneLinkState())
        fixture.vibrator.onCombo(combo, linkState: linkState(status: .finished))

        // then
        #expect(fixture.played.isEmpty)

        // when
        fixture.vibrator.onCombo(combo, linkState: linkState(status: .running))

        // then
        #expect(fixture.played == [Played(haptic: .directionUp, at: .zero)])
    }

    @Test
    func `러닝 중 큰 순간은 명단으로 센 인원만큼 울린다`() {
        // given -> 완두콩(u1)이 붙으면 콩나물(u2)과 나까지 셋이다
        let fixture = Fixture()
        let combo = WatchComboTriggered(eventId: "e1", userId: "u1", comboCount: 1, kind: .milestone)

        // when
        fixture.vibrator.onCombo(combo, linkState: linkState(status: .running))
        fixture.timer.advance(by: .seconds(1))

        // then
        #expect(fixture.played.count == 2)
    }

    private func linkState(status: RunStatus) -> PhoneLinkState {
        let sample = RunSamples.party
        let run = RunState(
            runningRoomId: sample.runningRoomId,
            type: sample.type,
            status: status,
            targetDistanceMeters: sample.targetDistanceMeters,
            isServerConnected: sample.isServerConnected,
            isPenaltyApplicable: sample.isPenaltyApplicable,
            me: sample.me,
            players: sample.players,
            finish: nil,
            result: nil
        )
        return PhoneLinkState(
            phoneState: PhoneState(
                phoneInstanceId: "p1",
                stateSequence: 1,
                statusVersion: 0,
                lastRequestId: nil,
                run: run
            )
        )
    }
}

private struct Played: Equatable {
    let haptic: WKHapticType
    let at: Duration
}

@MainActor
private final class Fixture {
    let timer = FakeTimer()
    var played: [Played] = []
    private let startedAt = ContinuousClock.now

    lazy var vibrator = RunVibrator(
        play: { [unowned self] in played.append(Played(haptic: $0, at: timer.now)) },
        now: { [unowned self] in startedAt + timer.now },
        schedule: timer.schedule
    )
}
