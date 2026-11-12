import SwiftUI

/// 심박 구간 막대다. 사람 색(레인 색)과 섞이지 않게 흰색 한 가지로 지금 구간까지 채운다.
struct HeartRateZoneBarView: View {
    let filledZoneCount: Int
    /// 막대 길이를 잴 심박 숫자 크기·굵기다. 그 옆에 그리는 심박과 같게 준다.
    let valueSize: CGFloat
    let valueWeight: SUITFont.Weight

    var body: some View {
        // 막대를 가장 넓은 심박 덩어리 폭으로 고정해 100을 넘어도 길이가 안 바뀌게 한다
        ValueWithUnitView(
            Self.widestHeartRate,
            unit: String(localized: "unit_bpm", bundle: .module),
            valueSize: valueSize,
            valueWeight: valueWeight,
            monospacesDigits: true
        )
        .hidden()
        .frame(height: RunDimensions.zoneBarHeight)
        .overlay {
            HStack(spacing: Self.zoneGap) {
                ForEach(0..<Self.zoneCount, id: \.self) { index in
                    Capsule().fill(index < filledZoneCount ? Color.white : RuniverseColors.emptyZone)
                }
            }
        }
    }

    private static let zoneCount = 5
    private static let zoneGap: CGFloat = 3
    private static let widestHeartRate = "888"
}

#Preview("심박 구간 막대 3칸") {
    VStack(spacing: 4) {
        ValueWithUnitView("148", unit: "bpm", valueSize: 18, monospacesDigits: true)
        HeartRateZoneBarView(filledZoneCount: 3, valueSize: 18, valueWeight: .semiBold)
    }
}
