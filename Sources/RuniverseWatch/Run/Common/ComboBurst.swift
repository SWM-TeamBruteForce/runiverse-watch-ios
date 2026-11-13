import CoreGraphics

/// 콤보 눈금에 닿아 화면 전체를 덮는 큰 순간이다.
struct ComboBurst: Equatable {
    let moment: ComboMoment
    let userId: String
    let comboCount: Int
}

/// 큰 순간 한 장면이다. 각도는 시계 방향이 양수다.
struct ComboBurstFrame: Equatable {
    let coverAlpha: Double
    let textScale: CGFloat
    let textAlpha: Double
    let textDegrees: Double
    let ringScale: CGFloat
    let ringAlpha: Double

    init(progress: Double) {
        let ringProgress = min(max(progress / Self.ringEndFraction, 0), 1)
        coverAlpha = Self.cover.value(at: progress)
        textScale = Self.textScales.value(at: progress)
        textAlpha = Self.textAlphas.value(at: progress)
        textDegrees = Self.textAngles.value(at: progress)
        ringScale = Self.ringStartScale + (Self.ringEndScale - Self.ringStartScale) * easeOut(ringProgress)
        ringAlpha = Self.ringStartAlpha * (1 - ringProgress)
    }

    /// 흰 테두리가 다 퍼졌을 때의 배율이다. 이때 화면 끝에 닿는다.
    static let ringEndScale: CGFloat = 2.4

    // 폰 임팩트를 따르고 끝만 다르다 — 날아갈 배지 자리가 없어 글자가 먼저 사라지고 덮개가 빨리 걷힌다
    private static let cover = [
        BurstSegment(weight: 10, from: 0, to: 1),
        BurstSegment(weight: 86, from: 1, to: 1),
        BurstSegment(weight: 4, from: 1, to: 0),
    ]
    private static let textScales = [
        BurstSegment(weight: 28, from: 0.3, to: 1.3, easesOut: true),
        BurstSegment(weight: 14, from: 1.3, to: 1),
        BurstSegment(weight: 58, from: 1, to: 1.02),
    ]
    private static let textAlphas = [
        BurstSegment(weight: 20, from: 0, to: 1),
        BurstSegment(weight: 70, from: 1, to: 1),
        BurstSegment(weight: 6, from: 1, to: 0),
        BurstSegment(weight: 4, from: 0, to: 0),
    ]
    private static let textAngles = [
        BurstSegment(weight: 28, from: -10, to: 3),
        BurstSegment(weight: 14, from: 3, to: 0),
        BurstSegment(weight: 58, from: 0, to: 0),
    ]

    private static let ringEndFraction = 0.56
    private static let ringStartScale: CGFloat = 0.35
    private static let ringStartAlpha = 0.95
}

/// 구간 비중과 시작·끝 값이다. Flutter `TweenSequence`처럼 이어 붙인다.
private struct BurstSegment {
    let weight: Double
    let from: Double
    let to: Double
    var easesOut = false
}

extension [BurstSegment] {
    fileprivate func value(at progress: Double) -> Double {
        let clamped = Swift.min(Swift.max(progress, 0), 1)
        let total = reduce(0) { $0 + $1.weight }
        var start = 0.0
        for segment in self {
            let end = start + segment.weight / total
            if clamped <= end {
                let local = end > start ? (clamped - start) / (end - start) : 1
                let eased = segment.easesOut ? easeOut(local) : local
                return segment.from + (segment.to - segment.from) * eased
            }
            start = end
        }
        return last?.to ?? 0
    }
}

private func easeOut(_ progress: Double) -> Double {
    1 - (1 - progress) * (1 - progress)
}
