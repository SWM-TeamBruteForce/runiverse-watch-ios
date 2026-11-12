import SwiftUI

/// 한 줄 글자다. 자리는 글자 상자가 아니라 잉크 윗변·가운데·아랫변으로 잡는다.
struct AlignedTextView: View {
    private let text: String
    private let size: CGFloat
    private let weight: SUITFont.Weight
    private let monospacesDigits: Bool
    private let color: Color
    private let placement: InkPlacement?

    /// `placement`는 `ScreenLayoutView` 안에서 화면 위 끝부터 잰 높이다. nil이면 부모 정렬을 따른다.
    /// `monospacesDigits`는 1초마다 바뀌는 내 수치에만 켠다 — 파티원 수는 원래 폭이 글자 간격이 고르다.
    init(
        _ text: String,
        size: CGFloat,
        weight: SUITFont.Weight = .semiBold,
        monospacesDigits: Bool = false,
        color: Color,
        placement: InkPlacement? = nil
    ) {
        self.text = text
        self.size = size
        self.weight = weight
        self.monospacesDigits = monospacesDigits
        self.color = color
        self.placement = placement
    }

    var body: some View {
        let ink = SUITFont.ink(for: text)
        let font = SUITFont.font(weight, size: size)
        Text(verbatim: text)
            .font(monospacesDigits ? font.monospacedDigit() : font)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .alignmentGuide(.inkCenter) {
                $0[.firstTextBaseline] - (ink.aboveBaselineEm - ink.belowBaselineEm) * size / 2
            }
            .alignmentGuide(.top) { dimensions in
                guard let placement else { return dimensions[.top] }
                return dimensions[.firstTextBaseline] - placement.baseline(ink: ink, size: size)
            }
    }
}

/// 잉크의 어느 변을 어느 높이에 둘지다.
enum InkPlacement: Equatable {
    case top(CGFloat)
    case center(CGFloat)
    case bottom(CGFloat)

    /// 그 변이 그 높이에 오게 하는 기준선 높이다.
    func baseline(ink: InkExtent, size: CGFloat) -> CGFloat {
        switch self {
        case .top(let y): y + ink.aboveBaselineEm * size
        case .center(let y): y + (ink.aboveBaselineEm - ink.belowBaselineEm) * size / 2
        case .bottom(let y): y - ink.belowBaselineEm * size
        }
    }
}

extension VerticalAlignment {
    private enum InkCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    /// 글자는 잉크 세로 가운데, 다른 View는 상자 세로 가운데다.
    static let inkCenter = VerticalAlignment(InkCenter.self)
}
