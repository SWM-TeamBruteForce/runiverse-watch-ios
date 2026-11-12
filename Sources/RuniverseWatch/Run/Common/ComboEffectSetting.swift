import Foundation

/// 콤보 효과 켜기·끄기다. 서버 설정이 아니라 워치에만 저장한다.
enum ComboEffectSetting {
    /// 화면은 이 키를 `@AppStorage`로 읽고 쓴다.
    static let key = "comboEffectOn"
    static let defaultIsOn = true

    /// 화면 밖에서 읽는다. 한 번도 바꾸지 않았으면 기본값이다.
    static func isOn(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: key) == nil ? defaultIsOn : defaults.bool(forKey: key)
    }
}
