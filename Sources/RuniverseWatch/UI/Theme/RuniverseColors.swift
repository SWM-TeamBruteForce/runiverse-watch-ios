import SwiftUI

/// 화면 색이다. 순백은 페이스 같은 큰 수와 버튼 글자에만 쓴다.
enum RuniverseColors {
    /// 수치와 읽는 글자다.
    static let value = Color(white: 250 / 255)

    /// 단위·보조 글자다. 가이드 라벨색 #575757은 대비가 2.9:1이라 흰색 70%로 쓴다.
    static let supporting = Color.white.opacity(0.7)

    static let buttonBackground = Color(white: 42 / 255)

    /// 심박 구간 막대의 아직 안 찬 칸이다.
    static let emptyZone = Color.white.opacity(0.25)
}
