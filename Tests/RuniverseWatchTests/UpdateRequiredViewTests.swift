import Testing

@testable import RuniverseWatch

struct UpdateRequiredViewTests {

    @Test
    func `거절 안내와 업데이트 버튼 문구를 쓴다`() {
        // when
        let content = UpdateRequiredContent()

        // then
        #expect(content.title == "워치 앱 업데이트 필요")
        #expect(content.subtitle == "폰 연결 불가")
        #expect(content.buttonLabel == "업데이트")
    }
}
