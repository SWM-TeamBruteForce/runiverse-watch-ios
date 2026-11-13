import Foundation
import Testing

@testable import RuniverseWatch

struct ComboEffectSettingTests {

    @Test
    func `한 번도 바꾸지 않았으면 켜져 있고 바꾼 값은 그대로 읽는다`() throws {
        // given
        let suiteName = "ComboEffectSettingTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // when & then
        #expect(ComboEffectSetting.isOn(in: defaults))

        // when -> 화면의 스위치가 끈다
        defaults.set(false, forKey: ComboEffectSetting.key)

        // then
        #expect(!ComboEffectSetting.isOn(in: defaults))
    }
}
