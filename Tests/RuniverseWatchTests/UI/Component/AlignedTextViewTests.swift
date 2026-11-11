import Testing

@testable import RuniverseWatch

struct AlignedTextViewTests {

    @Test
    func `잉크 윗변을 두면 기준선은 기준선 위 잉크 높이만큼 아래다`() {
        // when
        let baseline = InkPlacement.top(100).baseline(ink: SUITFont.hangulInk, size: 10)

        // then -> 100 + 0.814 × 10
        #expect(abs(baseline - 108.14) < 0.001)
    }

    @Test
    func `잉크 아랫변을 두면 기준선은 기준선 아래 잉크 깊이만큼 위다`() {
        // when
        let baseline = InkPlacement.bottom(100).baseline(ink: SUITFont.hangulInk, size: 10)

        // then -> 100 − 0.078 × 10
        #expect(abs(baseline - 99.22) < 0.001)
    }

    @Test
    func `잉크 가운데를 두면 기준선은 위아래 잉크 차이의 반만큼 아래다`() {
        // when
        let baseline = InkPlacement.center(100).baseline(ink: SUITFont.hangulInk, size: 10)

        // then -> 100 + (8.14 − 0.78) / 2
        #expect(abs(baseline - 103.68) < 0.001)
    }
}
