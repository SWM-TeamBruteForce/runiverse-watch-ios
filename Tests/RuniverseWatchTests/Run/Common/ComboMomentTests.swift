import Foundation
import Testing

@testable import RuniverseWatch

struct ComboMomentTests {

    @Test
    func `진행은 시작 전엔 0, 끝난 뒤엔 1로 막는다`() {
        // given
        let startedAt = Date(timeIntervalSinceReferenceDate: 0)
        let moment = ComboMoment(eventId: "e1", startedAt: startedAt)

        // when & then
        #expect(moment.progress(at: startedAt.addingTimeInterval(-1), duration: .milliseconds(320)) == 0)
        #expect(isClose(moment.progress(at: startedAt.addingTimeInterval(0.16), duration: .milliseconds(320)), 0.5))
        #expect(moment.progress(at: startedAt.addingTimeInterval(1), duration: .milliseconds(320)) == 1)
    }

    @Test
    func `흰 고리는 4분의 1까지 밝아지고 70%까지 머문 뒤 사라진다`() {
        // when & then
        #expect(ComboMoment.flashAlpha(progress: 0) == 0)
        #expect(isClose(ComboMoment.flashAlpha(progress: 0.125), 0.5))
        #expect(ComboMoment.flashAlpha(progress: 0.25) == 1)
        #expect(ComboMoment.flashAlpha(progress: 0.5) == 1)
        #expect(isClose(ComboMoment.flashAlpha(progress: 0.85), 0.5))
        #expect(ComboMoment.flashAlpha(progress: 1) == 0)
    }

    @Test
    func `콤보 글자는 45%에서 1점55배까지 컸다가 제 크기로 돌아온다`() {
        // when & then
        #expect(ComboMoment.bumpScale(progress: 0) == 1)
        #expect(isClose(ComboMoment.bumpScale(progress: 0.225), 1.275))
        #expect(isClose(ComboMoment.bumpScale(progress: 0.45), 1.55))
        #expect(isClose(ComboMoment.bumpScale(progress: 0.725), 1.1375))
        #expect(ComboMoment.bumpScale(progress: 1) == 1)
    }

    @Test
    func `효과를 끄면 큰 순간도 작은 순간이 되고 끊김은 띄우지 않는다`() {
        // when & then
        #expect(ComboMomentSize(kind: .tick, isEffectOn: true) == .small)
        #expect(ComboMomentSize(kind: .milestone, isEffectOn: true) == .big)
        #expect(ComboMomentSize(kind: .milestone, isEffectOn: false) == .small)
        #expect(ComboMomentSize(kind: .break, isEffectOn: true) == nil)
    }

    private func isClose(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 1e-9
    }
}
