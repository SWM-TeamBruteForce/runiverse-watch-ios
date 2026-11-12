import Testing

@testable import RuniverseWatch

struct RunPageSlotsTests {

    @Test
    func `첫 화면 묶음이 안전 영역 세로 가운데에 오게 큰 숫자 가운데를 잡는다`() {
        // given -> 46mm 시뮬레이터에서 잰 화면이다
        let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)
        let sizes = WatchFontSizes(screenWidth: screen.screenWidth)

        // when
        let slots = RunPageSlots(screen: screen, sizes: sizes)

        // then -> 위로 큰 숫자 반 19.133 + 묶음 간격 18 + 위 줄 12.996, 아래로 19.133 + 18 + 사진 줄 30.5 + 격차 10.108
        #expect(abs(slots.center - 118.694) < 0.001)
    }

    @Test
    func `40mm는 큰 숫자를 줄인 크기로 묶음 높이를 잰다`() {
        // given -> 40mm 시뮬레이터에서 잰 화면이다
        let screen = WatchScreen(screenWidth: 162, screenHeight: 197, safeAreaTop: 40, safeAreaBottom: 178)
        let sizes = WatchFontSizes(screenWidth: screen.screenWidth)

        // when
        let slots = RunPageSlots(screen: screen, sizes: sizes)

        // then -> 위로 큰 숫자 반 15.523 + 18 + 12.274, 아래로 15.523 + 18 + 30.5 + 9.386
        #expect(abs(slots.center - 95.194) < 0.001)
    }
}
