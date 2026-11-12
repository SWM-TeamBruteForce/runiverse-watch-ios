import CoreText
import SwiftUI
import os

/// SUIT 글꼴이다. 글자 크기 설정을 따르지 않고 고정한다.
enum SUITFont {
    enum Weight {
        case medium
        case semiBold
        case bold

        var postScriptName: String {
            switch self {
            case .medium: "SUIT-Medium"
            case .semiBold: "SUIT-SemiBold"
            case .bold: "SUIT-Bold"
            }
        }
    }

    static func font(_ weight: Weight, size: CGFloat) -> Font {
        _ = registration
        return .custom(weight.postScriptName, fixedSize: size)
    }

    /// 한 줄로 그렸을 때 글자 폭(pt)이다. 자간 보정까지 넣어 화면 글자 폭과 같다.
    static func width(of text: String, size: CGFloat, weight: Weight, monospacesDigits: Bool = false) -> CGFloat {
        _ = registration
        var descriptor = CTFontDescriptorCreateWithNameAndSize(weight.postScriptName as CFString, size)
        if monospacesDigits {
            descriptor = CTFontDescriptorCreateCopyWithFeature(
                descriptor,
                kNumberSpacingType as CFNumber,
                kMonospacedNumbersSelector as CFNumber
            )
        }
        let font = CTFontCreateWithFontDescriptor(descriptor, size, nil)
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
        )
        return CTLineGetTypographicBounds(line, nil, nil, nil)
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

/// 글자 잉크가 기준선 위아래로 차지하는 높이(em)다.
struct InkExtent: Equatable {
    let aboveBaselineEm: CGFloat
    let belowBaselineEm: CGFloat
}

extension SUITFont {
    /// 숫자·라틴 단위 — 폰트 파일 OS/2 표의 cap height 값이다.
    static let numeralInk = InkExtent(aboveBaselineEm: 0.722, belowBaselineEm: 0)

    /// 한글 — SemiBold 안내 문구 잉크를 잰 값이다.
    static let hangulInk = InkExtent(aboveBaselineEm: 0.814, belowBaselineEm: 0.078)

    /// 라틴 꼬리 글자(`bpm`의 p 등) — Medium 단위 잉크를 잰 값이다.
    static let descenderInk = InkExtent(aboveBaselineEm: 0.722, belowBaselineEm: 0.216)

    /// 글자 내용으로 잉크 높이를 고른다 — 한글·꼬리 글자는 숫자와 높이가 다르다.
    /// 여러 종류가 섞이면 위·아래 각각 가장 큰 쪽을 쓴다.
    static func ink(for text: String) -> InkExtent {
        var kinds = [numeralInk]
        if text.unicodeScalars.contains(where: hangulSyllables.contains) { kinds.append(hangulInk) }
        if text.contains(where: descenderLetters.contains) { kinds.append(descenderInk) }
        return InkExtent(
            aboveBaselineEm: kinds.map(\.aboveBaselineEm).max() ?? 0,
            belowBaselineEm: kinds.map(\.belowBaselineEm).max() ?? 0
        )
    }

    private static let hangulSyllables: ClosedRange<Unicode.Scalar> = "가"..."힣"
    private static let descenderLetters = "gjpqy"
}
