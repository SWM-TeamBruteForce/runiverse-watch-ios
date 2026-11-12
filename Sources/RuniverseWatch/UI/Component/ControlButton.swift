import SwiftUI

/// 화면 맨 아래에 하나만 두는 알약 버튼이다. 글자는 잉크 가운데, 아이콘은 상자 가운데를 알약 가운데에 맞춘다.
struct ControlButton: View {
    let label: String
    let icon: ControlIcon?
    let fontSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .inkCenter, spacing: Self.iconToLabelGap) {
                if let icon {
                    let iconSize = fontSize * Self.iconToFontRatio
                    ControlIconShape(icon: icon)
                        .stroke(.white, style: Self.lineIconStroke)
                        .frame(width: iconSize, height: iconSize)
                }
                AlignedTextView(label, size: fontSize, color: .white)
            }
            .frame(
                width: Self.width,
                height: Self.height,
                alignment: Alignment(horizontal: .center, vertical: .inkCenter)
            )
            .background(RuniverseColors.buttonBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    static let bottomPadding: CGFloat = 8

    // 화면 폭의 204/480이되 96보다 좁아지지 않는 갤럭시 규칙으로 재면 애플은 모든 화면이 96이다
    private static let width: CGFloat = 96
    private static let height: CGFloat = 48

    private static let iconToFontRatio: CGFloat = 0.62
    private static let iconToLabelGap: CGFloat = 6
    private static let lineIconStroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
}

enum ControlIcon {
    case upArrow
}

private struct ControlIconShape: Shape {
    let icon: ControlIcon

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch icon {
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

    private static let upArrowShaftEndFraction: CGFloat = 0.72
    private static let upArrowHeadFraction: CGFloat = 0.32
}
