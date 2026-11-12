import CoreGraphics
import Foundation

/// 화면에 띄우는 콤보 순간 하나다. 받은 시각부터 재 그린다.
struct ComboMoment: Equatable {
    let eventId: String
    let startedAt: Date

    /// `duration` 동안 0에서 1로 간다. 시작 전이면 0, 끝났으면 1이다.
    func progress(at date: Date, duration: Duration) -> Double {
        min(max(Duration.seconds(date.timeIntervalSince(startedAt)) / duration, 0), 1)
    }

    // 폰 배지가 튀는 시간과 같다
    static let smallDuration = Duration.milliseconds(320)

    // 폰 콤보 임팩트와 같은 길이다
    static let bigDuration = Duration.milliseconds(1200)

    /// 작은 순간 `progress`(0~1)에서 고리에 덮는 흰색의 투명도다.
    static func flashAlpha(progress: Double) -> Double {
        if progress <= 0 || progress >= 1 { return 0 }
        if progress < flashRiseEndFraction { return progress / flashRiseEndFraction }
        if progress < flashHoldEndFraction { return 1 }
        return (1 - progress) / (1 - flashHoldEndFraction)
    }

    /// 작은 순간 `progress`(0~1)에서 파티원 장 콤보 글자의 배율이다.
    static func bumpScale(progress: Double) -> CGFloat {
        if progress <= 0 || progress >= 1 { return 1 }
        if progress < bumpPeakFraction { return 1 + (bumpPeakToNormalRatio - 1) * progress / bumpPeakFraction }
        let settling = (progress - bumpPeakFraction) / (1 - bumpPeakFraction)
        let eased = 1 - (1 - settling) * (1 - settling)
        return bumpPeakToNormalRatio + (1 - bumpPeakToNormalRatio) * eased
    }

    private static let flashRiseEndFraction = 0.25
    private static let flashHoldEndFraction = 0.70
    private static let bumpPeakFraction = 0.45

    // 폰 배지가 튀는 크기와 같다
    private static let bumpPeakToNormalRatio: CGFloat = 1.55
}

/// 작은 순간은 그 사람 자리에서만, 큰 순간은 화면 전체를 덮는다.
enum ComboMomentSize {
    case small
    case big

    /// 효과를 끄면 큰 순간 터짐만 빠지고 작은 순간은 남는다. 끊김은 띄울 효과가 없어 nil이다.
    init?(kind: ComboKind, isEffectOn: Bool) {
        switch kind {
        case .tick: self = .small
        case .milestone: self = isEffectOn ? .big : .small
        case .break: return nil
        }
    }
}
