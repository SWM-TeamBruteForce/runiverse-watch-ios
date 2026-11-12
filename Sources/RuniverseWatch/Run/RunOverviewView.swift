import SwiftUI

/// 러닝 중 첫 화면이다. 위 줄 거리·시간, 가운데 내 페이스, 아래 파티원 사진·격차(혼자면 심박)다.
struct RunOverviewView: View {
    let run: RunState
    let isPhoneReachable: Bool
    let heartRateBpm: Int?
    let birthday: String?

    var body: some View {
        ScreenLayoutView { screen in
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let pageSlots = RunPageSlots(screen: screen, sizes: sizes)
            let slots = RunOverviewSlots(screen: screen, sizes: sizes)
            let content = RunOverviewContent(
                run: run,
                isPhoneReachable: isPhoneReachable,
                heartRateBpm: heartRateBpm,
                birthday: birthday,
                today: HeartRateZone.today(),
                abbreviateGapUnits: slots.abbreviateGapUnits
            )
            if let progress = content.progress {
                ProgressRingView(
                    progress: progress,
                    color: LaneColors.color(colorSlot: LaneColors.myColorSlot),
                    screen: screen
                )
                .opacity(content.phoneValuesAlpha)
            }
            DistanceTimeRow(
                content: content,
                sizes: sizes,
                width: RunPageSlots.topRowWidth(sizes: sizes),
                inkBottom: pageSlots.topRowBottom
            )
            .opacity(content.phoneValuesAlpha)
            AlignedTextView(
                content.centerText,
                size: content.isPaused ? WatchFontSizes.statusWordSize(numberSize: sizes.bigNumber) : sizes.bigNumber,
                weight: .bold,
                monospacesDigits: !content.isPaused,
                color: .white,
                placement: .center(pageSlots.center)
            )
            .opacity(content.phoneValuesAlpha)
            if content.players.isEmpty {
                SoloHeartRateView(content: content, sizes: sizes, top: pageSlots.belowRowTop)
            } else {
                HStack(spacing: 0) {
                    ForEach(content.players) { player in
                        PlayerAvatarView(player: player)
                            .frame(width: slots.playerCellWidth)
                            .opacity(player.avatarAlpha)
                    }
                }
                // 사진 칸은 콤보 고리까지라, 고리 두께만큼 올려 사진 원 윗변을 줄 자리에 둔다
                .alignmentGuide(.top) { _ in -(pageSlots.belowRowTop - RunDimensions.comboBorderWidth) }
                if content.isGapRowShown {
                    GapRow(
                        content: content,
                        sizes: sizes,
                        cellWidth: slots.playerCellWidth,
                        top: pageSlots.bottomRowTop
                    )
                }
            }
            if let notice = content.notice {
                AlignedTextView(
                    notice,
                    size: sizes.reading,
                    color: RuniverseColors.value,
                    placement: .top(pageSlots.bottomRowTop)
                )
            }
        }
    }
}

/// 첫 화면이 그릴 값이다.
struct RunOverviewContent: Equatable {
    /// 목표가 없으면(솔로) nil — 링을 그리지 않는다.
    let progress: Double?
    let distanceText: String
    let elapsedTimeText: String
    /// 멈췄으면 상태 글자, 아니면 지금 페이스다.
    let centerText: String
    let isPaused: Bool
    /// 폰이 끊기면 받은 값 전부를 마지막 값에서 멈춘 채 흐리게 둔다.
    let phoneValuesAlpha: Double
    let notice: String?
    let players: [PlayerCellContent]
    /// 끊긴 동안의 격차는 오래된 값이라 숨기고 그 자리에 안내를 띄운다.
    let isGapRowShown: Bool
    let heartRateText: String
    /// 생일이 없으면 nil — 막대를 숨긴다.
    let heartRateZone: Int?

    init(
        run: RunState,
        isPhoneReachable: Bool,
        heartRateBpm: Int?,
        birthday: String?,
        today: DateComponents,
        abbreviateGapUnits: Bool
    ) {
        progress = RunFormat.distanceProgress(run.me.distanceMeters, targetDistanceMeters: run.targetDistanceMeters)
        distanceText = RunFormat.formatRunDistanceKm(run.me.distanceMeters)
        elapsedTimeText = RunFormat.formatElapsedTime(run.me.elapsedSeconds)
        isPaused = run.status == .paused
        // 멈춘 동안은 지금 페이스가 없다
        centerText = isPaused ? RunTexts.paused : RunFormat.formatPace(run.me.currentPaceSecondsPerKm)
        phoneValuesAlpha = isPhoneReachable ? 1 : RunDimensions.staleContentAlpha
        notice = RunTexts.connectionNotice(run: run, isPhoneReachable: isPhoneReachable)
        players = run.players.map {
            PlayerCellContent($0, run: run, isPhoneReachable: isPhoneReachable, abbreviateGapUnits: abbreviateGapUnits)
        }
        isGapRowShown = notice == nil
        heartRateText = heartRateBpm.map(String.init) ?? RunTexts.valueUnknown
        heartRateZone = HeartRateZone.calculate(
            heartRateBpm: heartRateBpm,
            birthday: HeartRateZone.parseBirthday(birthday),
            today: today
        )
    }
}

/// 첫 화면 파티원 한 칸(사진·격차)이 그릴 값이다.
struct PlayerCellContent: Equatable, Identifiable {
    let id: String
    let colorSlot: Int
    /// 사진 대신 원 안에 쓰는 첫 글자다. 상태 아이콘이 가운데를 차지하면 없다.
    let initial: String?
    /// 사진에 덮개와 함께 얹을 상태다. 달리는 중이면 없다.
    let statusIcon: RunStatus?
    let isCombo: Bool
    let avatarAlpha: Double
    let gapLabel: GapLabel?
    let gapAlpha: Double

    init(_ player: Player, run: RunState, isPhoneReachable: Bool, abbreviateGapUnits: Bool) {
        id = player.userId
        colorSlot = player.colorSlot
        initial = player.status == .running ? String(player.nickname.prefix(1)) : nil
        statusIcon = player.status == .running ? nil : player.status
        // 폰이 콤보 없음과 막 붙음을 둘 다 0으로 보내 1 이상일 때만 고리를 두른다
        isCombo = player.comboCount > 0
        let hasStaleValues = player.hasStaleValues(in: run, isPhoneReachable: isPhoneReachable)
        avatarAlpha = hasStaleValues ? RunDimensions.staleContentAlpha : 1
        if let statusWord = RunTexts.statusWord(player.status) {
            gapLabel = .status(statusWord)
        } else if let gapMeters = player.gapMeters {
            gapLabel = .gap(
                GapDirection(gapMeters: gapMeters),
                RunFormat.formatGapDistance(gapMeters, abbreviateUnits: abbreviateGapUnits)
            )
        } else {
            // 그 사람 통지가 아직 없으면 폰도 격차 줄을 그리지 않는다
            gapLabel = nil
        }
        // 폰·서버가 끊기면 격차 줄 대신 안내가 떠, 격차는 그 사람 소식이 늦을 때만 흐린다
        gapAlpha = player.isStale ? RunDimensions.staleContentAlpha : 1
    }
}

/// 사진 아래 한 칸에 쓰는 것이다.
enum GapLabel: Equatable {
    case status(String)
    case gap(GapDirection, FormattedDistance)
}

/// 첫 화면 칸 폭(pt)이다. 값이 바뀌어도 안 움직이게 나올 수 있는 가장 넓은 값으로 잰다.
struct RunOverviewSlots: Equatable {
    /// 가장 넓은 격차 셋이 링 안에 안 들어가는 화면이다. 값이 아니라 화면으로 정해 모양이 안 바뀐다.
    let abbreviateGapUnits: Bool
    let playerCellWidth: CGFloat

    init(screen: WatchScreen, sizes: WatchFontSizes) {
        let fullLabelWidth = Self.widestGapLabelWidth(readingSize: sizes.reading, abbreviateUnits: false)
        let fullCellWidth = Self.playerCellWidth(screenWidth: screen.screenWidth, labelWidth: fullLabelWidth)
        abbreviateGapUnits = !Self.gapLabelsFit(
            screenWidth: screen.screenWidth,
            cellWidth: fullCellWidth,
            labelWidth: fullLabelWidth
        )
        if abbreviateGapUnits {
            let shortLabelWidth = Self.widestGapLabelWidth(readingSize: sizes.reading, abbreviateUnits: true)
            playerCellWidth = Self.playerCellWidth(screenWidth: screen.screenWidth, labelWidth: shortLabelWidth)
        } else {
            playerCellWidth = fullCellWidth
        }
    }

    private static func widestGapLabelWidth(readingSize: CGFloat, abbreviateUnits: Bool) -> CGFloat {
        let widths = widestGapsMeters.map { gapMeters in
            let gap = RunFormat.formatGapDistance(gapMeters, abbreviateUnits: abbreviateUnits)
            let valueWidth = ValueWithUnitView.width(
                gap.value,
                unit: RunTexts.distanceUnit(gap.unit),
                valueSize: readingSize
            )
            return directionIndicatorWidth + directionIndicatorToValueGap + valueWidth
        }
        return widths.max() ?? 0
    }

    private static func playerCellWidth(screenWidth: CGFloat, labelWidth: CGFloat) -> CGFloat {
        max(screenWidth * minPlayerCellWidthFraction, labelWidth + minGapLabelToCellGap)
    }

    // 파티원이 가장 많을 때 맨 왼쪽 격차 글자가 링 안쪽 글자 여백 안에서 시작하는지 본다
    private static func gapLabelsFit(screenWidth: CGFloat, cellWidth: CGFloat, labelWidth: CGFloat) -> Bool {
        let rowLeft = (screenWidth - cellWidth * CGFloat(maxPlayerCount)) / 2
        return rowLeft + (cellWidth - labelWidth) / 2 >= RunDimensions.textEdgeMargin
    }

    static let directionIndicatorWidth: CGFloat = 7.5
    static let directionIndicatorHeight: CGFloat = 6.6
    static let directionIndicatorToValueGap: CGFloat = 2

    // 파티원 수는 원래 폭이라 0이 가장 넓고 4가 다음이다
    private static let widestGapsMeters = [400, 4_000]
    private static let minPlayerCellWidthFraction: CGFloat = 110 / 480
    private static let minGapLabelToCellGap: CGFloat = 4

    // 4인 방에서 나를 뺀 수다
    private static let maxPlayerCount = 3
}

private struct DistanceTimeRow: View {
    let content: RunOverviewContent
    let sizes: WatchFontSizes
    let width: CGFloat
    let inkBottom: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ValueWithUnitView(
                content.distanceText,
                unit: RunTexts.kilometerUnit,
                valueSize: sizes.value,
                monospacesDigits: true
            )
            Spacer(minLength: 0)
            AlignedTextView(
                content.elapsedTimeText,
                size: sizes.value,
                monospacesDigits: true,
                color: RuniverseColors.value
            )
        }
        .frame(width: width)
        // 숫자·km는 기준선 아래로 안 내려가 기준선이 곧 잉크 아랫변이다
        .alignmentGuide(.top) { $0[.firstTextBaseline] - inkBottom }
    }
}

// 심박은 워치가 재는 값이라 폰이 끊겨도 흐리지 않는다
private struct SoloHeartRateView: View {
    let content: RunOverviewContent
    let sizes: WatchFontSizes
    let top: CGFloat

    var body: some View {
        let unit = RunTexts.heartRateUnit
        let ink = ValueWithUnitView.ink(value: content.heartRateText, unit: unit, valueSize: sizes.value)
        ValueWithUnitView(
            content.heartRateText,
            unit: unit,
            valueSize: sizes.value,
            monospacesDigits: true,
            placement: .top(top)
        )
        if let zone = content.heartRateZone {
            HeartRateZoneBarView(filledZoneCount: zone, valueSize: sizes.value, valueWeight: .semiBold)
                .alignmentGuide(.top) { _ in -(top + ink.above + ink.below + RunDimensions.valueToZoneBarGap) }
        }
    }
}

private struct PlayerAvatarView: View {
    let player: PlayerCellContent

    var body: some View {
        let lane = LaneColors.color(colorSlot: player.colorSlot)
        let avatarSize = RunDimensions.avatarSize
        let borderWidth = RunDimensions.comboBorderWidth
        ZStack(alignment: Alignment(horizontal: .center, vertical: .inkCenter)) {
            Circle().fill(lane).frame(width: avatarSize, height: avatarSize)
            // TODO: 파티원 사진 — 사진을 만들 때 폰이 보낸 사진을 그린다
            if let initial = player.initial {
                AlignedTextView(initial, size: WatchFontSizes.supporting, weight: .bold, color: .white)
            }
            if let statusIcon = player.statusIcon {
                Circle()
                    .fill(Color.black.opacity(Self.statusOverlayAlpha))
                    .frame(width: avatarSize, height: avatarSize)
                StatusIconView(status: statusIcon)
                    .frame(width: avatarSize * Self.statusIconFraction, height: avatarSize * Self.statusIconFraction)
            }
            if player.isCombo {
                // 나와 상대의 레인 색을 섞어 누구와 붙었는지 알 수 있게 한다
                let myLane = LaneColors.color(colorSlot: LaneColors.myColorSlot)
                Circle()
                    .stroke(
                        LinearGradient(colors: [myLane, lane], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: borderWidth
                    )
                    .frame(width: avatarSize + borderWidth, height: avatarSize + borderWidth)
            }
        }
        .frame(width: avatarSize + borderWidth * 2, height: avatarSize + borderWidth * 2)
    }

    private static let statusOverlayAlpha = 0.6
    private static let statusIconFraction: CGFloat = 0.42
}

private struct StatusIconView: View {
    let status: RunStatus

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let white = GraphicsContext.Shading.color(.white)
            switch status {
            case .paused:
                let barWidth = width * 0.28
                for barX in [width * 0.12, width * 0.88 - barWidth] {
                    context.fill(Path(CGRect(x: barX, y: 0, width: barWidth, height: height)), with: white)
                }
            case .finished:
                var check = Path()
                check.move(to: CGPoint(x: width * 0.08, y: height * 0.52))
                check.addLine(to: CGPoint(x: width * 0.4, y: height * 0.82))
                check.addLine(to: CGPoint(x: width * 0.94, y: height * 0.2))
                context.stroke(check, with: white, style: StrokeStyle(lineWidth: width * 0.16, lineCap: .round))
            case .disconnected:
                let stroke = StrokeStyle(lineWidth: width * 0.12, lineCap: .round)
                let center = CGPoint(x: width / 2, y: height * 0.9)
                for radiusFraction in [0.85, 0.55] {
                    var arc = Path()
                    arc.addArc(
                        center: center,
                        radius: width * radiusFraction,
                        startAngle: .degrees(225),
                        endAngle: .degrees(315),
                        clockwise: false
                    )
                    context.stroke(arc, with: white, style: stroke)
                }
                let dotRadius = width * 0.09
                let dot = CGRect(x: center.x, y: center.y, width: 0, height: 0).insetBy(dx: -dotRadius, dy: -dotRadius)
                context.fill(Path(ellipseIn: dot), with: white)
                var slash = Path()
                slash.move(to: .zero)
                slash.addLine(to: CGPoint(x: width, y: height))
                context.stroke(slash, with: white, style: stroke)
            case .running:
                break
            }
        }
    }
}

private struct GapRow: View {
    let content: RunOverviewContent
    let sizes: WatchFontSizes
    let cellWidth: CGFloat
    let top: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(content.players) { player in
                GapLabelView(label: player.gapLabel, sizes: sizes)
                    .frame(width: cellWidth)
                    .opacity(player.gapAlpha)
            }
        }
        // 상태 글자는 윗변이 높아 윗변으로 맞추면 옆 사람 격차까지 밀린다 — 숫자 기준선에 맞춘다
        .alignmentGuide(.top) { $0[.firstTextBaseline] - (top + sizes.reading * SUITFont.numeralInk.aboveBaselineEm) }
    }
}

private struct GapLabelView: View {
    let label: GapLabel?
    let sizes: WatchFontSizes

    var body: some View {
        switch label {
        case .status(let word):
            let statusSize = WatchFontSizes.statusWordSize(numberSize: sizes.reading)
            AlignedTextView(word, size: statusSize, color: RuniverseColors.value)
                .alignmentGuide(.firstTextBaseline) {
                    $0[.firstTextBaseline] + Self.statusWordRaise(statusSize: statusSize, numberSize: sizes.reading)
                }
        case .gap(let direction, let distance):
            HStack(alignment: .firstTextBaseline, spacing: RunOverviewSlots.directionIndicatorToValueGap) {
                if direction != .level {
                    // 앞/뒤에 색을 주면 레인 색과 겹치고 좋다/나쁘다로 읽혀서 흰색으로 둔다
                    GapDirectionShape(pointsUp: direction == .ahead)
                        .fill(RuniverseColors.value)
                        .frame(
                            width: RunOverviewSlots.directionIndicatorWidth,
                            height: RunOverviewSlots.directionIndicatorHeight
                        )
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                }
                ValueWithUnitView(distance.value, unit: RunTexts.distanceUnit(distance.unit), valueSize: sizes.reading)
            }
        case nil:
            Color.clear.frame(height: 0)
        }
    }

    // 상태 글자의 잉크 세로 가운데를 옆 숫자 잉크 가운데에 맞추려고 기준선에서 올릴 높이다
    nonisolated private static func statusWordRaise(statusSize: CGFloat, numberSize: CGFloat) -> CGFloat {
        let above = statusSize * SUITFont.hangulInk.aboveBaselineEm
        let below = statusSize * SUITFont.hangulInk.belowBaselineEm
        return below - (above + below - numberSize * SUITFont.numeralInk.aboveBaselineEm) / 2
    }
}

private struct GapDirectionShape: Shape {
    let pointsUp: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsUp {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

#Preview("첫 화면 파티") {
    RunOverviewView(run: RunSamples.party, isPhoneReachable: true, heartRateBpm: 148, birthday: RunSamples.birthday)
}

#Preview("첫 화면 솔로") {
    RunOverviewView(run: RunSamples.solo, isPhoneReachable: true, heartRateBpm: 148, birthday: RunSamples.birthday)
}

#Preview("첫 화면 멈춤") {
    RunOverviewView(run: RunSamples.paused, isPhoneReachable: true, heartRateBpm: 92, birthday: RunSamples.birthday)
}

#Preview("첫 화면 긴 값") {
    RunOverviewView(
        run: RunSamples.longValues,
        isPhoneReachable: true,
        heartRateBpm: 148,
        birthday: RunSamples.birthday
    )
}

#Preview("첫 화면 파티원 상태") {
    RunOverviewView(
        run: RunSamples.playerStatuses,
        isPhoneReachable: true,
        heartRateBpm: 148,
        birthday: RunSamples.birthday
    )
}

#Preview("첫 화면 서버 끊김") {
    RunOverviewView(
        run: RunSamples.serverLost,
        isPhoneReachable: true,
        heartRateBpm: 148,
        birthday: RunSamples.birthday
    )
}

#Preview("첫 화면 폰 끊김") {
    RunOverviewView(run: RunSamples.party, isPhoneReachable: false, heartRateBpm: 148, birthday: RunSamples.birthday)
}
