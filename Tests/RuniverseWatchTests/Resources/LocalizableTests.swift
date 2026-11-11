import Foundation
import Testing

@testable import RuniverseWatch

struct LocalizableTests {

    @Test
    func `기기 언어에 맞는 문구가 없으면 한국어 문구를 쓴다`() {
        // given
        let resource = LocalizedStringResource(
            "idle_start_on_phone",
            locale: Locale(identifier: "en"),
            bundle: .atURL(Bundle.module.bundleURL)
        )

        // when & then
        #expect(String(localized: resource) == "폰에서 러닝 시작")
    }
}
