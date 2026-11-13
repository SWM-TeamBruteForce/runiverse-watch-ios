import Testing

@testable import RuniverseWatch

struct IdleViewTests {

    @Test
    func `폰이 닿으면 할 일과 자동 표시 안내를 쓴다`() {
        // when
        let content = IdleContent(isPhoneReachable: true)

        // then
        #expect(content.title == "폰에서 러닝 시작")
        #expect(content.subtitle == "러닝 화면 자동 표시")
    }

    @Test
    func `폰이 끊기면 확인 중 한 줄만 쓴다`() {
        // when
        let content = IdleContent(isPhoneReachable: false)

        // then
        #expect(content.title == "폰 연결 확인 중")
        #expect(content.subtitle == nil)
    }
}
