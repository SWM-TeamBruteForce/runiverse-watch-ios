import Testing
import UIKit

@testable import RuniverseWatch

struct SUITFontTests {

    @Test
    func `글꼴을 처음 쓰면 패키지 번들의 SUIT가 등록된다`() {
        // when
        _ = SUITFont.semiBold(size: 14)

        // then
        #expect(UIFont(name: "SUIT-SemiBold", size: 14) != nil)
    }
}
