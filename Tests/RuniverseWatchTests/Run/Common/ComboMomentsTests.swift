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
        fixture.moments.onCombo(combo("e1", userId: "u2", kind: .tick))

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
        fixture.moments.onCombo(combo("e1", userId: "u2", kind: .milestone))

        // then
        #expect(fixture.moments.smallMoments["u2"]?.eventId == "e1")
    }

    @Test
    func `효과가 켜져 있으면 큰 순간은 작은 순간으로 띄우지 않는다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)

        // when
        fixture.moments.onCombo(combo("e1", userId: "u2", kind: .milestone))

        // then
        #expect(fixture.moments.smallMoments.isEmpty)
    }

    @Test
    func `끊김은 띄우지 않는다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)

        // when
        fixture.moments.onCombo(combo("e1", userId: "u2", kind: .break))

        // then
        #expect(fixture.moments.smallMoments.isEmpty)
    }

    @Test
    func `어둡거나 꺼진 화면에 온 콤보는 띄우지 않는다`() {
        // given -> 화면이 켜진 적 없이 시작한다
        let fixture = Fixture()

        // when
        fixture.moments.onCombo(combo("e1", userId: "u2", kind: .tick))
        fixture.moments.onScreenActiveChanged(true)

        // then -> 켜진 뒤에도 지난 순간을 뒤늦게 띄우지 않는다
        #expect(fixture.moments.smallMoments.isEmpty)
    }

    @Test
    func `화면이 어두워지면 띄우던 작은 순간을 지운다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)
        fixture.moments.onCombo(combo("e1", userId: "u2", kind: .tick))

        // when
        fixture.moments.onScreenActiveChanged(false)

        // then
        #expect(fixture.moments.smallMoments.isEmpty)
    }

    @Test
    func `같은 사람의 새 순간은 앞 순간을 지우는 시간에 지워지지 않는다`() {
        // given
        let fixture = Fixture()
        fixture.moments.onScreenActiveChanged(true)
        fixture.moments.onCombo(combo("e1", userId: "u2", kind: .tick))

        // when -> 0.2초 뒤 같은 사람이 또 오른다
        fixture.timer.advance(by: .milliseconds(200))
        fixture.moments.onCombo(combo("e2", userId: "u2", kind: .tick))
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
        fixture.moments.onCombo(combo("e1", userId: "u1", kind: .tick))
        fixture.moments.onCombo(combo("e2", userId: "u2", kind: .tick))

        // then
        #expect(fixture.moments.smallMoments["u1"]?.eventId == "e1")
        #expect(fixture.moments.smallMoments["u2"]?.eventId == "e2")
    }

    private func combo(_ eventId: String, userId: String, kind: ComboKind) -> WatchComboTriggered {
        WatchComboTriggered(eventId: eventId, userId: userId, comboCount: 3, kind: kind)
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
}
