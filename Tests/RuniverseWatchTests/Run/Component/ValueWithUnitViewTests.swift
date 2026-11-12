import Testing

@testable import RuniverseWatch

struct ValueWithUnitViewTests {

    @Test
    func `큰 숫자에 꼬리 있는 단위를 붙이면 위는 숫자, 아래는 단위 꼬리로 잰다`() {
        // when
        let ink = ValueWithUnitView.ink(value: "148", unit: "bpm", valueSize: 53)

        // then -> 위 0.722 × 53, 아래 0.216 × 단위 12
        #expect(abs(ink.above - 38.266) < 0.001)
        #expect(abs(ink.below - 2.592) < 0.001)
    }

    @Test
    func `숫자보다 단위가 크면 위도 단위로 잰다`() {
        // when
        let ink = ValueWithUnitView.ink(value: "3", unit: "km", valueSize: 10)

        // then -> 숫자 0.722 × 10보다 단위 0.722 × 12가 높다
        #expect(abs(ink.above - 8.664) < 0.001)
        #expect(ink.below == 0)
    }

    @Test
    func `단위가 없으면 숫자 잉크만 쓴다`() {
        // when
        let ink = ValueWithUnitView.ink(value: "24:10", unit: nil, valueSize: 18)

        // then -> 0.722 × 18
        #expect(abs(ink.above - 12.996) < 0.001)
        #expect(ink.below == 0)
    }
}
