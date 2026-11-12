import SwiftUI

/// 알약 버튼이다. 글자는 잉크 가운데, 아이콘은 상자 가운데를 알약 가운데에 맞춘다.
struct ControlButton: View {
    let label: String
    let icon: ControlIcon?
    let fontSize: CGFloat
    var width = bottomButtonWidth
    var background = RuniverseColors.buttonBackground
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .inkCenter, spacing: Self.iconToLabelGap) {
                if let icon {
                    ControlIconView(icon: icon, size: fontSize * Self.iconToFontRatio)
                }
                AlignedTextView(label, size: fontSize, color: .white)
            }
            .frame(
                width: width,
                height: Self.pillHeight,
                alignment: Alignment(horizontal: .center, vertical: .inkCenter)
            )
            .background(background, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    static let bottomPadding: CGFloat = 8
    nonisolated static let pillHeight: CGFloat = 48

    // 화면 맨 아래에 하나만 두는 버튼 폭이다
    // 화면 폭의 204/480이되 96보다 좁아지지 않는 갤럭시 규칙으로 재면 애플은 모든 화면이 96이다
    private static let bottomButtonWidth: CGFloat = 96
    private static let iconToFontRatio: CGFloat = 0.62
    private static let iconToLabelGap: CGFloat = 6
}

enum ControlIcon {
    case pause
    case play
    case stop
    case upArrow
}

/// 선 아이콘은 긋고, 나머지는 채운다.
private struct ControlIconView: View {
    let icon: ControlIcon
    let size: CGFloat

    var body: some View {
        let shape = ControlIconShape(icon: icon)
        Group {
            if icon == .upArrow {
                shape.stroke(.white, style: Self.lineIconStroke)
            } else {
                shape.fill(.white)
            }
        }
        .frame(width: size, height: size)
    }

    private static let lineIconStroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
}

private struct ControlIconShape: Shape {
    let icon: ControlIcon

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch icon {
        case .pause:
            let barWidth = rect.width * Self.pauseBarFraction
            for barFraction in [Self.pauseLeftBarFraction, Self.pauseRightBarFraction] {
                path.addRect(
                    CGRect(x: rect.minX + rect.width * barFraction, y: rect.minY, width: barWidth, height: rect.height)
                )
            }
        case .play:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        case .stop:
            path.addRect(rect)
        case .upArrow:
            let head = rect.width * Self.upArrowHeadFraction
            path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * Self.upArrowShaftEndFraction))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.move(to: CGPoint(x: rect.midX - head, y: rect.minY + head))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX + head, y: rect.minY + head))
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        return path
    }

    private static let pauseBarFraction: CGFloat = 0.28
    private static let pauseLeftBarFraction: CGFloat = 0.1
    private static let pauseRightBarFraction: CGFloat = 0.62
    private static let upArrowShaftEndFraction: CGFloat = 0.72
    private static let upArrowHeadFraction: CGFloat = 0.32
}
