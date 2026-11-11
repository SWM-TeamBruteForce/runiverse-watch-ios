import CoreText
import SwiftUI
import os

/// SUIT 글꼴이다. 글자 크기 설정을 따르지 않고 고정한다.
enum SUITFont {
    static func semiBold(size: CGFloat) -> Font {
        _ = registration
        return .custom("SUIT-SemiBold", fixedSize: size)
    }

    // 글꼴이 앱 번들이 아니라 패키지 번들에 있어 앱이 올리지 않아, 처음 쓸 때 코드로 등록한다
    private static let registration: Void = {
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        if urls.isEmpty { logger.error("글꼴 파일 없음") }
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let cause = String(describing: error?.takeRetainedValue())
                logger.error("글꼴 등록 실패 — \(url.lastPathComponent, privacy: .public): \(cause, privacy: .public)")
            }
        }
    }()

    private static let logger = Logger(subsystem: "RuniverseWatch", category: "SUITFont")
}
