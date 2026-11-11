import SwiftUI

/// 워치 앱의 화면 전체를 담는다. 앱 타깃은 진입점에서 이것만 띄운다.
public struct RuniverseWatchScene: Scene {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            // TODO: 뼈대 확인용 글자 — 대기 화면을 만들 때 교체한다
            Text(verbatim: "Runiverse")
        }
    }
}
