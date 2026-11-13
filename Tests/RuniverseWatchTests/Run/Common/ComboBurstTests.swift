import Testing

@testable import RuniverseWatch

struct ComboBurstTests {

    @Test
    func `덮개는 처음 10%에 덮이고 마지막 4%에 걷힌다`() {
        // when & then
        #expect(ComboBurstFrame(progress: 0).coverAlpha == 0)
        #expect(isClose(ComboBurstFrame(progress: 0.05).coverAlpha, 0.5))
        #expect(isClose(ComboBurstFrame(progress: 0.1).coverAlpha, 1))
        #expect(ComboBurstFrame(progress: 0.5).coverAlpha == 1)
        #expect(isClose(ComboBurstFrame(progress: 0.98).coverAlpha, 0.5))
        #expect(ComboBurstFrame(progress: 1).coverAlpha == 0)
    }

    @Test
    func `글자는 28%에 1점3배로 가장 크고 42%에 기울기 없이 제 크기가 된다`() {
        // when & then
        #expect(isClose(ComboBurstFrame(progress: 0).textScale, 0.3))
        #expect(isClose(ComboBurstFrame(progress: 0).textDegrees, -10))
        #expect(isClose(ComboBurstFrame(progress: 0.28).textScale, 1.3))
        #expect(isClose(ComboBurstFrame(progress: 0.28).textDegrees, 3))
        #expect(isClose(ComboBurstFrame(progress: 0.42).textScale, 1))
        #expect(isClose(ComboBurstFrame(progress: 0.42).textDegrees, 0))
        #expect(isClose(ComboBurstFrame(progress: 1).textScale, 1.02))
    }

    @Test
    func `글자는 덮개보다 먼저 사라진다`() {
        // when
        let frame = ComboBurstFrame(progress: 0.96)

        // then
        #expect(isClose(frame.textAlpha, 0))
        #expect(frame.coverAlpha == 1)
    }

    @Test
    func `흰 테두리는 56%에 화면 끝까지 퍼지며 사라진다`() {
        // when & then
        #expect(isClose(ComboBurstFrame(progress: 0).ringScale, 0.35))
        #expect(isClose(ComboBurstFrame(progress: 0).ringAlpha, 0.95))
        #expect(isClose(ComboBurstFrame(progress: 0.56).ringScale, ComboBurstFrame.ringEndScale))
        #expect(isClose(ComboBurstFrame(progress: 0.56).ringAlpha, 0))
        #expect(isClose(ComboBurstFrame(progress: 1).ringAlpha, 0))
    }

    private func isClose(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 1e-9
    }
}
