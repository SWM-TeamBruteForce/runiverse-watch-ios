import SwiftUI

/// 사람마다 쓰는 레인 색이다. 폰과 같아야 같은 사람이 같은 색으로 보인다.
enum LaneColors {
    /// 나는 늘 0번 레인 색이다.
    static let myColorSlot = 0

    /// 0은 나, 1~3은 파티원이다.
    static func color(colorSlot: Int) -> Color {
        colors[(colorSlot % colors.count + colors.count) % colors.count]
    }

    private static let colors = [
        Color(red: 0x22 / 255, green: 0x7D / 255, blue: 0xFF / 255),
        Color(red: 0xFF / 255, green: 0x83 / 255, blue: 0x35 / 255),
        Color(red: 0xFF / 255, green: 0x4F / 255, blue: 0xA3 / 255),
        Color(red: 0x33 / 255, green: 0xD1 / 255, blue: 0x7A / 255),
    ]
}
