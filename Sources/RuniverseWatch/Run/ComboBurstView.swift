import SwiftUI

/// 콤보 눈금에 닿은 순간 화면 전체를 1.2초 덮는다. 시계는 시스템이 그려 덮이지 않는다.
struct ComboBurstView: View {
    let burst: ComboBurst
    let player: Player

    var body: some View {
        let content = ComboBurstContent(burst: burst, player: player)
        ZStack {
            // 덮개가 검어 뒤 장이 안 보인다 — 터치를 받아 덮인 채 장이 넘어가지 않게 한다
            Color.clear
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0))
                .ignoresSafeArea()
            TimelineView(.animation) { context in
                let progress = burst.moment.progress(at: context.date, duration: ComboMoment.bigDuration)
                ComboBurstFrameView(content: content, frame: ComboBurstFrame(progress: progress))
            }
            .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }
}

/// 큰 순간이 그릴 값이다.
struct ComboBurstContent: Equatable {
    let countText: String
    let word: String
    let nickname: String
    let initial: String
    let colorSlot: Int
    let accessibilityLabel: String

    init(burst: ComboBurst, player: Player) {
        countText = String(burst.comboCount)
        word = String(localized: "run_combo_burst_word", bundle: .module)
        nickname = player.nickname
        initial = String(player.nickname.prefix(1))
        colorSlot = player.colorSlot
        accessibilityLabel = String(
            localized: "run_combo_burst_description \(burst.comboCount) \(player.nickname)",
            bundle: .module
        )
    }
}

/// 큰 순간 한 장면이다.
private struct ComboBurstFrameView: View {
    let content: ComboBurstContent
    let frame: ComboBurstFrame

    var body: some View {
        let textAlpha = frame.textAlpha * frame.coverAlpha
        ScreenLayoutView { screen in
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let pageSlots = RunPageSlots(screen: screen, sizes: sizes)
            Color.black.opacity(frame.coverAlpha)
            SpreadingRingView(frame: frame, screen: screen)
                .opacity(frame.ringAlpha * frame.coverAlpha)
            BurstHeadlineView(content: content, sizes: sizes, center: pageSlots.center, screen: screen, frame: frame)
                .opacity(textAlpha)
            BurstPlayerRow(content: content, sizes: sizes, top: pageSlots.belowRowTop, screen: screen)
                .opacity(textAlpha)
        }
    }
}

// 흰 테두리는 화면 모양을 따른다 — 다 퍼지면 화면 끝에 닿는다
private struct SpreadingRingView: View {
    let frame: ComboBurstFrame
    let screen: WatchScreen

    var body: some View {
        let fraction = frame.ringScale / ComboBurstFrame.ringEndScale
        RoundedRectangle(cornerRadius: screen.cornerRadius * fraction)
            .stroke(Color.white, lineWidth: Self.strokeWidth * frame.ringScale)
            .frame(width: screen.screenWidth * fraction, height: screen.screenHeight * fraction)
            .position(x: screen.screenWidth / 2, y: screen.screenHeight / 2)
    }

    private static let strokeWidth: CGFloat = 1.5
}

/// 기울어진 `10 COMBO`다. 숫자 잉크 세로 가운데를 큰 숫자 자리에 두고 그 점을 축으로 키우고 돌린다.
private struct BurstHeadlineView: View {
    let content: ComboBurstContent
    let sizes: WatchFontSizes
    let center: CGFloat
    let screen: WatchScreen
    let frame: ComboBurstFrame

    var body: some View {
        let countSize = sizes.bigNumber
        let baseline = InkPlacement.center(center).baseline(ink: SUITFont.ink(for: content.countText), size: countSize)
        let pivot = UnitPoint(x: 0.5, y: center / screen.screenHeight)
        let myLane = LaneColors.color(colorSlot: LaneColors.myColorSlot)
        let lane = LaneColors.color(colorSlot: content.colorSlot)
        // 판을 화면 크기로 채워 기울이고 키우고 돌리는 축을 화면 좌표로 잡는다
        ZStack(alignment: .top) {
            Color.clear
            HStack(alignment: .firstTextBaseline, spacing: Self.countToWordGap) {
                // 숫자를 나→흰→상대 레인 색으로 칠해 누구와 붙었는지 보인다
                AlignedTextView(content.countText, size: countSize, weight: .bold, color: .clear)
                    .overlay {
                        LinearGradient(colors: [myLane, .white, lane], startPoint: .leading, endPoint: .trailing)
                            .mask {
                                AlignedTextView(content.countText, size: countSize, weight: .bold, color: .white)
                            }
                    }
                AlignedTextView(content.word, size: sizes.reading, weight: .bold, color: .white)
            }
            .alignmentGuide(.top) { $0[.firstTextBaseline] - baseline }
        }
        .frame(width: screen.screenWidth, height: screen.screenHeight)
        .transformEffect(Self.italic(baseline: baseline))
        .scaleEffect(frame.textScale, anchor: pivot)
        .rotationEffect(.degrees(frame.textDegrees), anchor: pivot)
    }

    // 기준선을 축으로 위쪽을 오른쪽으로 민다
    private static func italic(baseline: CGFloat) -> CGAffineTransform {
        let slant = tan(italicDegrees * .pi / 180)
        return CGAffineTransform(a: 1, b: 0, c: -slant, d: 1, tx: slant * baseline, ty: 0)
    }

    private static let countToWordGap: CGFloat = 8

    // SUIT엔 기울임 글꼴이 없어 기계가 기울이는 각도로 폰의 기울임 글꼴을 흉내 낸다
    private static let italicDegrees = 14.0
}

// 끝나면 첫 화면의 그 사람 사진으로 이어지게 사진 줄 자리에 사진과 이름을 둔다
private struct BurstPlayerRow: View {
    let content: ComboBurstContent
    let sizes: WatchFontSizes
    let top: CGFloat
    let screen: WatchScreen

    var body: some View {
        let avatarSize = RunDimensions.avatarSize
        let borderWidth = RunDimensions.comboBorderWidth
        let lane = LaneColors.color(colorSlot: content.colorSlot)
        let myLane = LaneColors.color(colorSlot: LaneColors.myColorSlot)
        let nameWidth = min(
            SUITFont.width(of: content.nickname, size: sizes.reading, weight: .semiBold),
            screen.screenWidth * Self.maxNameWidthFraction
        )
        HStack(alignment: .inkCenter, spacing: Self.avatarToNameGap) {
            ZStack(alignment: Alignment(horizontal: .center, vertical: .inkCenter)) {
                Circle().fill(lane).frame(width: avatarSize, height: avatarSize)
                // TODO: 파티원 사진 — 사진을 만들 때 폰이 보낸 사진을 그린다
                AlignedTextView(content.initial, size: WatchFontSizes.supporting, weight: .bold, color: .white)
                Circle()
                    .stroke(
                        LinearGradient(colors: [myLane, lane], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: borderWidth
                    )
                    .frame(width: avatarSize + borderWidth, height: avatarSize + borderWidth)
            }
            .frame(width: avatarSize + borderWidth * 2, height: avatarSize + borderWidth * 2)
            AlignedTextView(content.nickname, size: sizes.reading, color: RuniverseColors.value, truncatesTail: true)
                .frame(width: nameWidth)
        }
        // 사진 칸은 콤보 고리까지라, 고리 두께만큼 올려 사진 원 윗변을 줄 자리에 둔다
        .alignmentGuide(.top) { _ in -(top - borderWidth) }
    }

    private static let avatarToNameGap: CGFloat = 6
    private static let maxNameWidthFraction: CGFloat = 0.62
}

#Preview("큰 순간 자리 잡음") {
    ComboBurstFrameView(
        content: ComboBurstContent(
            burst: ComboBurst(
                moment: ComboMoment(eventId: "e1", startedAt: Date()),
                userId: RunSamples.party.players[1].userId,
                comboCount: 10
            ),
            player: RunSamples.party.players[1]
        ),
        frame: ComboBurstFrame(progress: 0.5)
    )
}
