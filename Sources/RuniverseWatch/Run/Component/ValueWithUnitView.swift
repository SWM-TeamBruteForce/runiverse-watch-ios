import SwiftUI

/// 숫자와 단위를 기준선에 맞춰 한 덩어리로 그린다. 가운데 정렬은 이 덩어리로 한다.
struct ValueWithUnitView: View {
    private let value: String
    private let unit: String?
    private let valueSize: CGFloat
    private let valueWeight: SUITFont.Weight
    private let monospacesDigits: Bool
    private let valueColor: Color
    private let placement: InkPlacement?

    /// `placement`는 숫자와 단위를 합친 잉크로 잡는다 — 더 높은 윗변과 더 낮은 아랫변이다.
    init(
        _ value: String,
        unit: String?,
        valueSize: CGFloat,
        valueWeight: SUITFont.Weight = .semiBold,
        monospacesDigits: Bool = false,
        valueColor: Color = RuniverseColors.value,
        placement: InkPlacement? = nil
    ) {
        self.value = value
        self.unit = unit
        self.valueSize = valueSize
        self.valueWeight = valueWeight
        self.monospacesDigits = monospacesDigits
        self.valueColor = valueColor
        self.placement = placement
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.valueToUnitGap) {
            AlignedTextView(
                value,
                size: valueSize,
                weight: valueWeight,
                monospacesDigits: monospacesDigits,
                color: valueColor
            )
            if let unit {
                AlignedTextView(
                    unit,
                    size: WatchFontSizes.supporting,
                    weight: .medium,
                    color: RuniverseColors.supporting
                )
            }
        }
        .alignmentGuide(.top) { dimensions in
            guard let placement else { return dimensions[.top] }
            let ink = Self.ink(value: value, unit: unit, valueSize: valueSize)
            return dimensions[.firstTextBaseline] - placement.baseline(inkAbove: ink.above, inkBelow: ink.below)
        }
    }

    /// 덩어리 잉크가 기준선 위아래로 차지하는 높이(pt)다. 숫자와 단위 중 더 높은 윗변과 더 낮은 아랫변이다.
    nonisolated static func ink(value: String, unit: String?, valueSize: CGFloat) -> (above: CGFloat, below: CGFloat) {
        let valueInk = SUITFont.ink(for: value)
        let unitInk = unit.map(SUITFont.ink(for:))
        let unitSize = WatchFontSizes.supporting
        return (
            above: max(valueInk.aboveBaselineEm * valueSize, (unitInk?.aboveBaselineEm ?? 0) * unitSize),
            below: max(valueInk.belowBaselineEm * valueSize, (unitInk?.belowBaselineEm ?? 0) * unitSize)
        )
    }

    /// 덩어리 폭(pt)이다. 칸 폭을 가장 넓은 값으로 잴 때 쓴다.
    nonisolated static func width(
        _ value: String,
        unit: String?,
        valueSize: CGFloat,
        valueWeight: SUITFont.Weight = .semiBold,
        monospacesDigits: Bool = false
    ) -> CGFloat {
        let valueWidth = SUITFont.width(
            of: value,
            size: valueSize,
            weight: valueWeight,
            monospacesDigits: monospacesDigits
        )
        guard let unit else { return valueWidth }
        return valueWidth + valueToUnitGap + SUITFont.width(of: unit, size: WatchFontSizes.supporting, weight: .medium)
    }

    nonisolated private static let valueToUnitGap: CGFloat = 2
}

#Preview("숫자와 단위 내 기록") {
    VStack(spacing: 12) {
        ValueWithUnitView("3.42", unit: "km", valueSize: 18, monospacesDigits: true)
        ValueWithUnitView("148", unit: "bpm", valueSize: 53, valueWeight: .bold, valueColor: .white)
        ValueWithUnitView("--", unit: "spm", valueSize: 18)
    }
}
