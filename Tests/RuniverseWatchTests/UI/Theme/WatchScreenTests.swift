import Testing

@testable import RuniverseWatch

struct WatchScreenTests {

    // 46mm 시뮬레이터에서 잰 화면이다. 모서리 반지름은 34.32다
    private let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)

    @Test
    func `모서리 곡선이 아닌 높이에선 양쪽 여백만 뺀 폭을 쓴다`() {
        // when & then
        #expect(screen.usableWidth(atY: 124, margin: 12.5) == 183)
    }

    @Test
    func `모서리 곡선 높이에선 곡선만큼 더 좁다`() {
        // given -> 여백 안쪽 곡선 반지름 21.82, 곡선은 위에서 34.32까지다
        let y = 20.0

        // when
        let width = screen.usableWidth(atY: y, margin: 12.5)

        // then -> 곡선 중심에서 14.32 위라 양쪽이 21.82 − √(21.82² − 14.32²) = 5.3564씩 더 들어간다
        #expect(abs(width - 172.2872) < 0.001)
    }

    @Test
    func `여백 밖 높이에선 쓸 수 있는 폭이 없다`() {
        // when & then
        #expect(screen.usableWidth(atY: 10, margin: 12.5) == 0)
        #expect(screen.usableWidth(atY: 240, margin: 12.5) == 0)
    }
}
