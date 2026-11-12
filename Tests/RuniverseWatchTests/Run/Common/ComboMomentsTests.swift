import Foundation
import Testing

@testable import RuniverseWatch

@MainActor
struct ComboMomentsTests {

    @Test
    func `밝은 화면에서 1 오름은 그 사람 작은 순간을 띄우고 0점32초 뒤 지운다`() throws {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)

        // when
        fixture.receive(combo("e1", userId: "u2", kind: .tick))

        // then
        let moment = try #require(fixture.moments.smallMoments["u2"])
        #expect(moment.eventId == "e1")

        // when
        fixture.timer.advance(by: .milliseconds(320))

        // then
        #expect(fixture.moments.smallMoments.isEmpty)
    }

    @Test
    func `효과를 끄면 큰 순간도 작은 순간으로 띄운다`() {
        // given
        let fixture = Fixture()
        fixture.isEffectOn = false
        fixture.moments.onScreenActiveChanged(true)

        // when
        fixture.receive(combo("e1", userId: "u2", kind: .milestone))

        // then
        #expect(fixture.moments.smallMoments["u2"]?.eventId == "e1")
        #expect(fixture.moments.burst == nil)
    }

    @Test
    func `밝은 화면에서 큰 순간은 1점2초 동안 덮고 작은 순간으로는 띄우지 않는다`() throws {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)

        // when
        fixture.receive(combo("e1", userId: "u2", comboCount: 10, kind: .milestone))

        // then
        let burst = try #require(fixture.moments.burst)
        #expect(burst.userId == "u2")
        #expect(burst.comboCount == 10)
        #expect(fixture.moments.smallMoments.isEmpty)

        // when
        fixture.timer.advance(by: .milliseconds(1200))

        // then
        #expect(fixture.moments.burst == nil)
    }

    @Test
    func `큰 순간이 덮는 동안 온 다음 큰 순간은 무시한다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)
        fixture.receive(combo("e1", userId: "u2", kind: .milestone))

        // when
        fixture.timer.advance(by: .milliseconds(600))
        fixture.receive(combo("e2", userId: "u1", kind: .milestone))

        // then
        #expect(fixture.moments.burst?.moment.eventId == "e1")

        // when -> 앞 순간이 끝나도 무시한 순간을 뒤늦게 띄우지 않는다
        fixture.timer.advance(by: .milliseconds(600))

        // then
        #expect(fixture.moments.burst == nil)
    }

    @Test
    func `조작 장에선 큰 순간을 띄우지 않고 작은 순간은 띄운다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)
        fixture.moments.onControlsShownChanged(true)

        // when
        fixture.receive(combo("e1", userId: "u2", kind: .milestone))
        fixture.receive(combo("e2", userId: "u1", kind: .tick))

        // then
        #expect(fixture.moments.burst == nil)
        #expect(fixture.moments.smallMoments["u1"]?.eventId == "e2")

        // when -> 첫 화면으로 돌아온다
        fixture.moments.onControlsShownChanged(false)
        fixture.receive(combo("e3", userId: "u2", kind: .milestone))

        // then
        #expect(fixture.moments.burst?.moment.eventId == "e3")
    }

    @Test
    func `조작 장으로 넘어가면 덮던 큰 순간을 지운다`() {
        // given -> 첫 화면에서 큰 순간이 뜬 채로 조작 장으로 넘긴다
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)
        fixture.receive(combo("e1", userId: "u2", kind: .milestone))

        // when
        fixture.moments.onControlsShownChanged(true)

        // then
        #expect(fixture.moments.burst == nil)
    }

    @Test
    func `명단에 없는 사람이나 끝난 러닝의 큰 순간은 띄우지 않는다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)

        // when
        fixture.receive(combo("e1", userId: "u9", kind: .milestone))
        fixture.moments.onCombo(combo("e2", userId: "u2", kind: .milestone), linkState: PhoneLinkState())

        // then
        #expect(fixture.moments.burst == nil)
    }

    @Test
    func `끊김은 띄우지 않는다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)

        // when
        fixture.receive(combo("e1", userId: "u2", kind: .break))

        // then
        #expect(fixture.moments.smallMoments.isEmpty)
        #expect(fixture.moments.burst == nil)
    }

    @Test
    func `어둡거나 꺼진 화면에 온 콤보는 띄우지 않는다`() {
        // given -> 화면이 밝아진 적 없이 시작한다
        let fixture = Fixture()

        // when
        fixture.receive(combo("e1", userId: "u2", kind: .tick))
        fixture.receive(combo("e2", userId: "u1", kind: .milestone))
        fixture.moments.onScreenActiveChanged(true)

        // then -> 밝아진 뒤에도 지난 순간을 뒤늦게 띄우지 않는다
        #expect(fixture.moments.smallMoments.isEmpty)
        #expect(fixture.moments.burst == nil)
    }

    @Test
    func `화면이 어두워지면 띄우던 순간을 지운다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)
        fixture.receive(combo("e1", userId: "u2", kind: .tick))
        fixture.receive(combo("e2", userId: "u1", kind: .milestone))

        // when
        fixture.moments.onScreenActiveChanged(false)

        // then
        #expect(fixture.moments.smallMoments.isEmpty)
        #expect(fixture.moments.burst == nil)
    }

    @Test
    func `같은 사람의 새 순간은 앞 순간을 지우는 시간에 지워지지 않는다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)
        fixture.receive(combo("e1", userId: "u2", kind: .tick))

        // when -> 0.2초 뒤 같은 사람이 또 오른다
        fixture.timer.advance(by: .milliseconds(200))
        fixture.receive(combo("e2", userId: "u2", kind: .tick))
        fixture.timer.advance(by: .milliseconds(120))

        // then
        #expect(fixture.moments.smallMoments["u2"]?.eventId == "e2")

        // when
        fixture.timer.advance(by: .milliseconds(200))

        // then
        #expect(fixture.moments.smallMoments.isEmpty)
    }

    @Test
    func `한 통지에 여러 사람이 오르면 사람마다 띄운다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)

        // when
        fixture.receive(combo("e1", userId: "u1", kind: .tick))
        fixture.receive(combo("e2", userId: "u2", kind: .tick))

        // then
        #expect(fixture.moments.smallMoments["u1"]?.eventId == "e1")
        #expect(fixture.moments.smallMoments["u2"]?.eventId == "e2")
    }

    private func combo(_ eventId: String, userId: String, comboCount: Int = 3, kind: ComboKind) -> WatchComboTriggered {
        WatchComboTriggered(eventId: eventId, userId: userId, comboCount: comboCount, kind: kind)
    }
}

@MainActor
private final class Fixture {
    let timer = FakeTimer()
    var isEffectOn = true
    private let startedAt = Date(timeIntervalSinceReferenceDate: 0)

    lazy var moments = ComboMoments(
        now: { [unowned self] in startedAt.addingTimeInterval(timer.now / .seconds(1)) },
        schedule: timer.schedule,
        isEffectOn: { [unowned self] in isEffectOn }
    )

    // 샘플 파티(완두콩 u1·콩나물 u2·강낭콩 u3)가 달리는 중에 받는다
    func receive(_ combo: WatchComboTriggered) {
        let phoneState = PhoneState(
            phoneInstanceId: "p1",
            stateSequence: 1,
            statusVersion: 0,
            lastRequestId: nil,
            run: RunSamples.party
        )
        moments.onCombo(combo, linkState: PhoneLinkState(phoneState: phoneState))
    }
}
