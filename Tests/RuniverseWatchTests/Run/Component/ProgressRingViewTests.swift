import Testing

@testable import RuniverseWatch

struct ProgressRingViewTests {

    // 46mm 시뮬레이터에서 잰 화면이다
    private let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)

    @Test
    func `링은 오른쪽 변 안전 영역 위 끝에서 시작해 위쪽 변 화면 가운데에서 끝난다`() {
        // when
        let slots = ProgressRingSlots(screen: screen)

        // then
        #expect(slots.startY == 53)
        #expect(slots.endX == 104)
    }

    @Test
    func `둥근 끝이 빈칸으로 나가지 않게 두께 절반만큼 안쪽에서 시작하고 끝낸다`() {
        // given -> 모서리 반지름 28.32, 선 길이는 변 넷 549.08 + 모서리 셋 133.456
        let slots = ProgressRingSlots(screen: screen)

        // when
        let full = slots.trimRange(progress: 1)

        // then -> 두께 절반 2.5 / 682.536
        #expect(abs((full?.lowerBound ?? 0) - 0.003663) < 0.000001)
        #expect(abs((full?.upperBound ?? 0) - 0.996337) < 0.000001)
    }

    @Test
    func `진행이 없으면 색을 칠하지 않고, 목표를 넘으면 끝까지만 칠한다`() {
        // given
        let slots = ProgressRingSlots(screen: screen)

        // when & then
        #expect(slots.trimRange(progress: 0) == nil)
        #expect(slots.trimRange(progress: 1.3) == slots.trimRange(progress: 1))
    }
}
