import CoreGraphics

/// 화면 단계별 글자 크기(pt)다. 자리마다 크기를 하나로 고정한다.
struct WatchFontSizes: Equatable {
    let bigNumber: CGFloat
    let value: CGFloat
    let reading: CGFloat

    /// 단위·보조 글자는 화면 단계와 상관없이 같다.
    static let supporting: CGFloat = 12

    /// 숫자 자리에 드는 상태 글자(멈춤·끊김·마침) 크기다. 숫자와 같은 크기면 튀어 보여 조금 줄인다.
    static func statusWordSize(numberSize: CGFloat) -> CGFloat {
        numberSize * statusToNumberRatio
    }

    private static let statusToNumberRatio: CGFloat = 0.93

    init(screenWidth: CGFloat) {
        if screenWidth >= Self.smallScreenBelow {
            self = Self.largeScreen
        } else if screenWidth >= Self.narrowestScreenBelow {
            self = Self.smallScreen
        } else {
            self = Self.narrowestScreen
        }
    }

    private init(bigNumber: CGFloat, value: CGFloat, reading: CGFloat) {
        self.bigNumber = bigNumber
        self.value = value
        self.reading = reading
    }

    private static let largeScreen = WatchFontSizes(bigNumber: 53, value: 18, reading: 14)
    private static let smallScreen = WatchFontSizes(bigNumber: 47, value: 17, reading: 13)

    // 가장 긴 페이스가 작은 단계 큰 숫자로도 링 밖으로 나가, 큰 숫자만 더 줄인다
    private static let narrowestScreen = WatchFontSizes(bigNumber: 43, value: 17, reading: 13)

    // 큰 숫자 53으로 가장 긴 페이스가 링 안에 드는 화면이 큰 단계다
    // 46mm 208pt·울트라 211pt는 크고 42mm 187pt·SE 44mm 184pt는 작다
    private static let smallScreenBelow: CGFloat = 195

    // 41mm 176pt까지는 작은 단계가 들어가고, 40mm 162pt만 큰 숫자를 줄인다
    private static let narrowestScreenBelow: CGFloat = 176
}
