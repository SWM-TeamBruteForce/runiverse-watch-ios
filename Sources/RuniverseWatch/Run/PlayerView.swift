import SwiftUI

/// 러닝 중 파티원 장이다. 위 줄 그 사람 거리·이름, 가운데 격차, 아래 상대·나 페이스와 콤보다.
struct PlayerView: View {
    let run: RunState
    let player: Player
    let isPhoneReachable: Bool
    /// 이 사람과 지금 띄우는 작은 순간이다.
    var smallComboMoment: ComboMoment?

    var body: some View {
        let content = PlayerContent(run: run, player: player, isPhoneReachable: isPhoneReachable)
        ScreenLayoutView { screen in
            let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
            let pageSlots = RunPageSlots(screen: screen, sizes: sizes)
            let slots = PlayerSlots(screen: screen, sizes: sizes)
            if let progress = content.progress {
                ProgressRingView(
                    progress: progress,
                    color: LaneColors.color(colorSlot: content.colorSlot),
                    screen: screen
                )
                .opacity(content.playerValuesAlpha)
            }
            DistanceNameRow(
                content: content,
                sizes: sizes,
                width: RunPageSlots.topRowWidth(sizes: sizes),
                inkBottom: pageSlots.topRowBottom
            )
            .opacity(content.playerValuesAlpha)
            PlayerCenterView(center: content.center, sizes: sizes, pageSlots: pageSlots)
                .opacity(content.playerValuesAlpha)
            PaceRows(content: content, sizes: sizes, slots: slots, top: pageSlots.belowRowTop)
            switch content.bottomLabel {
            case .combo(let text):
                ComboRow(text: text, top: slots.comboRowTop, smallComboMoment: smallComboMoment)
                    .opacity(content.playerValuesAlpha)
            case .notice(let notice):
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

/// 파티원 장이 그릴 값이다.
struct PlayerContent: Equatable {
    /// 목표가 없으면 nil — 링을 그리지 않는다.
    let progress: Double?
    let colorSlot: Int
    let distanceText: String
    let nickname: String
    let center: PlayerCenter
    /// 끊긴 동안은 오래된 상대 페이스를 숨긴다.
    let playerPaceText: String?
    let myPaceText: String
    let bottomLabel: PlayerBottomLabel
    /// 폰·서버가 끊겼거나 그 사람 소식이 늦으면 그 사람 값을 흐린다.
    let playerValuesAlpha: Double
    /// 서버가 끊겨도 내 페이스는 폰이 계속 재는 값이라 폰이 끊길 때만 흐린다.
    let phoneValuesAlpha: Double

    init(run: RunState, player: Player, isPhoneReachable: Bool) {
        progress = RunFormat.distanceProgress(player.distanceMeters, targetDistanceMeters: run.targetDistanceMeters)
        colorSlot = player.colorSlot
        distanceText = RunFormat.formatRunDistanceKm(player.distanceMeters)
        nickname = player.nickname
        center = PlayerCenter(player)
        let notice = RunTexts.connectionNotice(run: run, isPhoneReachable: isPhoneReachable)
        playerPaceText = notice == nil ? RunFormat.formatPace(player.shownPaceSecondsPerKm) : nil
        myPaceText = RunFormat.formatPace(run.shownMyPaceSecondsPerKm)
        if let notice {
            bottomLabel = .notice(notice)
        } else if player.comboCount > 0 {
            bottomLabel = .combo(String(localized: "run_combo_current \(player.comboCount)", bundle: .module))
        } else {
            bottomLabel = .combo(String(localized: "run_combo_max \(player.maxComboCount)", bundle: .module))
        }
        let hasStaleValues = player.hasStaleValues(in: run, isPhoneReachable: isPhoneReachable)
        playerValuesAlpha = hasStaleValues ? RunDimensions.staleContentAlpha : 1
        phoneValuesAlpha = isPhoneReachable ? 1 : RunDimensions.staleContentAlpha
    }
}

/// 파티원 장 가운데에 쓰는 것이다.
enum PlayerCenter: Equatable {
    case status(String)
    /// 앞·뒤 글자는 나란히면 없다.
    case gap(directionWord: String?, distance: FormattedDistance)

    init(_ player: Player) {
        if let statusWord = RunTexts.statusWord(player.status) {
            self = .status(statusWord)
        } else if let gapMeters = player.gapMeters {
            let directionWord: String? =
                switch GapDirection(gapMeters: gapMeters) {
                case .ahead: String(localized: "run_gap_ahead", bundle: .module)
                case .behind: String(localized: "run_gap_behind", bundle: .module)
                case .level: nil
                }
            self = .gap(
                directionWord: directionWord,
                distance: RunFormat.formatGapDistance(gapMeters, abbreviateUnits: false)
            )
        } else {
            // `0m`과 같은 꼴이라 통지가 와도 덩어리 가운데가 안 움직인다
            self = .gap(directionWord: nil, distance: FormattedDistance(value: RunTexts.valueUnknown, unit: .meter))
        }
    }
}

/// 파티원 장 맨 아래 줄에 쓰는 것이다. 끊긴 동안은 콤보 자리를 연결 안내가 대신한다.
enum PlayerBottomLabel: Equatable {
    case combo(String)
    case notice(String)
}

/// 파티원 장 자리(화면 위 끝에서 pt)와 페이스 칸 폭이다. 칸은 값이 바뀌어도 안 움직이게 가장 넓은 값으로 잰다.
struct PlayerSlots: Equatable {
    let playerPaceCellWidth: CGFloat
    let myPaceCellWidth: CGFloat
    /// 가장 넓은 두 페이스가 한 줄에 들어간다. 값이 아니라 화면으로 정해 달리는 중 모양이 안 바뀐다.
    let pacesFitOneLine: Bool
    /// 페이스 줄 잉크가 기준선 위로 올라가는 높이다.
    let paceRowAbove: CGFloat
    /// 페이스 줄 잉크가 기준선 아래로 내려가는 높이다 — 라벨 한글 꼬리다.
    let paceRowBelow: CGFloat
    /// 콤보 줄 잉크의 윗변이다. 페이스가 두 줄이면 맨 아래 줄 자리까지 내려와 그 아래로 간다.
    let comboRowTop: CGFloat

    init(screen: WatchScreen, sizes: WatchFontSizes) {
        let pageSlots = RunPageSlots(screen: screen, sizes: sizes)
        playerPaceCellWidth = Self.labeledPaceWidth(
            label: PlayerTexts.playerPaceLabel,
            pace: Self.widestPlayerPace,
            paceSize: sizes.value,
            monospacesDigits: false
        )
        myPaceCellWidth = Self.labeledPaceWidth(
            label: PlayerTexts.myPaceLabel,
            pace: Self.widestMyPace,
            paceSize: sizes.value,
            monospacesDigits: true
        )
        let labelSize = WatchFontSizes.supporting
        paceRowAbove = max(
            sizes.value * SUITFont.numeralInk.aboveBaselineEm,
            labelSize * SUITFont.hangulInk.aboveBaselineEm
        )
        paceRowBelow = labelSize * SUITFont.hangulInk.belowBaselineEm
        let firstBaseline = pageSlots.belowRowTop + paceRowAbove
        pacesFitOneLine =
            playerPaceCellWidth + Self.paceGap + myPaceCellWidth
            <= screen.usableWidth(atY: firstBaseline, margin: RunDimensions.textEdgeMargin)
        let rowCount: CGFloat = pacesFitOneLine ? 1 : 2
        let paceRowsHeight = (paceRowAbove + paceRowBelow) * rowCount + RunDimensions.lineGap * (rowCount - 1)
        comboRowTop = max(pageSlots.bottomRowTop, pageSlots.belowRowTop + paceRowsHeight + RunDimensions.lineGap)
    }

    private static func labeledPaceWidth(
        label: String,
        pace: String,
        paceSize: CGFloat,
        monospacesDigits: Bool
    ) -> CGFloat {
        SUITFont.width(of: label, size: WatchFontSizes.supporting, weight: .medium)
            + labelToPaceGap
            + SUITFont.width(of: pace, size: paceSize, weight: .semiBold, monospacesDigits: monospacesDigits)
    }

    static let labelToPaceGap: CGFloat = 3
    static let paceGap: CGFloat = 8

    // 상대 페이스는 원래 폭이라 0이 가장 넓고, 분 앞자리(5까지) 중엔 4가 가장 넓다
    private static let widestPlayerPace = "40'00\""

    // 같은 폭 숫자라도 SUIT는 1 다음 1에 자간이 붙어, 11이 가장 많은 값이 가장 넓다
    private static let widestMyPace = "11'11\""
}

private enum PlayerTexts {
    static let playerPaceLabel = String(localized: "run_pace_player", bundle: .module)
    static let myPaceLabel = String(localized: "run_pace_me", bundle: .module)
}

// 거리와 이름은 글자 종류·크기가 달라 기준선 대신 보이는 글자의 세로 가운데를 맞춘다
private struct DistanceNameRow: View {
    let content: PlayerContent
    let sizes: WatchFontSizes
    let width: CGFloat
    let inkBottom: CGFloat

    var body: some View {
        let distanceInk = ValueWithUnitView.ink(
            value: content.distanceText,
            unit: RunTexts.kilometerUnit,
            valueSize: sizes.value
        )
        let nameInk = SUITFont.ink(for: content.nickname)
        let nameBaselineDrop =
            (nameInk.aboveBaselineEm - nameInk.belowBaselineEm) * sizes.reading / 2
            - (distanceInk.above - distanceInk.below) / 2
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ValueWithUnitView(content.distanceText, unit: RunTexts.kilometerUnit, valueSize: sizes.value)
            Spacer(minLength: Self.minDistanceToNameGap)
            AlignedTextView(content.nickname, size: sizes.reading, color: RuniverseColors.value, truncatesTail: true)
                .alignmentGuide(.firstTextBaseline) { $0[.firstTextBaseline] - nameBaselineDrop }
        }
        .frame(width: width)
        // 숫자·km는 기준선 아래로 안 내려가 기준선이 곧 잉크 아랫변이다
        .alignmentGuide(.top) { $0[.firstTextBaseline] - inkBottom }
    }

    private static let minDistanceToNameGap: CGFloat = 8
}

private struct PlayerCenterView: View {
    let center: PlayerCenter
    let sizes: WatchFontSizes
    let pageSlots: RunPageSlots

    var body: some View {
        switch center {
        case .status(let word):
            AlignedTextView(
                word,
                size: WatchFontSizes.statusWordSize(numberSize: sizes.bigNumber),
                weight: .bold,
                color: .white,
                placement: .center(pageSlots.center)
            )
        case .gap(let directionWord, let distance):
            HStack(alignment: .firstTextBaseline, spacing: Self.directionWordToValueGap) {
                if let directionWord {
                    AlignedTextView(directionWord, size: sizes.reading, color: RuniverseColors.supporting)
                }
                ValueWithUnitView(
                    distance.value,
                    unit: RunTexts.distanceUnit(distance.unit),
                    valueSize: sizes.bigNumber,
                    valueWeight: .bold,
                    valueColor: .white
                )
            }
            .alignmentGuide(.top) { $0[.firstTextBaseline] - pageSlots.bigNumberBaseline }
        }
    }

    private static let directionWordToValueGap: CGFloat = 2
}

private struct PaceRows: View {
    let content: PlayerContent
    let sizes: WatchFontSizes
    let slots: PlayerSlots
    let top: CGFloat

    var body: some View {
        let firstBaseline = top + slots.paceRowAbove
        let myPace = LabeledPaceView(
            label: PlayerTexts.myPaceLabel,
            pace: content.myPaceText,
            paceSize: sizes.value,
            monospacesDigits: true
        )
        .opacity(content.phoneValuesAlpha)
        if let playerPaceText = content.playerPaceText {
            let playerPace = LabeledPaceView(
                label: PlayerTexts.playerPaceLabel,
                pace: playerPaceText,
                paceSize: sizes.value,
                monospacesDigits: false
            )
            .opacity(content.playerValuesAlpha)
            if slots.pacesFitOneLine {
                // 상대 값이 바뀌어도 내 페이스가 안 움직이게 칸 폭을 가장 넓은 페이스로 잡는다
                HStack(alignment: .firstTextBaseline, spacing: PlayerSlots.paceGap) {
                    playerPace.frame(width: slots.playerPaceCellWidth, alignment: .trailing)
                    myPace.frame(width: slots.myPaceCellWidth, alignment: .leading)
                }
                .alignmentGuide(.top) { $0[.firstTextBaseline] - firstBaseline }
            } else {
                // 둘째 줄은 첫 줄 라벨 꼬리 아래에서 줄 간격만큼 띄운다
                let secondBaseline = firstBaseline + slots.paceRowBelow + RunDimensions.lineGap + slots.paceRowAbove
                playerPace
                    .alignmentGuide(.top) { $0[.firstTextBaseline] - firstBaseline }
                myPace
                    .alignmentGuide(.top) { $0[.firstTextBaseline] - secondBaseline }
            }
        } else {
            myPace
                .alignmentGuide(.top) { $0[.firstTextBaseline] - firstBaseline }
        }
    }
}

private struct LabeledPaceView: View {
    let label: String
    let pace: String
    let paceSize: CGFloat
    let monospacesDigits: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PlayerSlots.labelToPaceGap) {
            AlignedTextView(label, size: WatchFontSizes.supporting, weight: .medium, color: RuniverseColors.supporting)
            AlignedTextView(pace, size: paceSize, monospacesDigits: monospacesDigits, color: RuniverseColors.value)
        }
    }
}

/// 맨 아래 콤보 줄이다. 작은 순간엔 한 번 튄다.
private struct ComboRow: View {
    let text: String
    let top: CGFloat
    let smallComboMoment: ComboMoment?

    var body: some View {
        let size = WatchFontSizes.supporting
        let ink = SUITFont.ink(for: text)
        let inkCenter = top + (ink.aboveBaselineEm + ink.belowBaselineEm) * size / 2
        // 상자 가운데로 키우면 꼬리 글자가 아래로 치우쳐, 잉크 가운데를 크기 0인 판에 붙여 키운다
        TimelineView(.animation(paused: smallComboMoment == nil)) { context in
            let progress = smallComboMoment?.progress(at: context.date, duration: ComboMoment.smallDuration)
            Color.clear
                .frame(width: 0, height: 0)
                .overlay(alignment: Alignment(horizontal: .center, vertical: .inkCenter)) {
                    AlignedTextView(text, size: size, weight: .medium, color: RuniverseColors.supporting)
                }
                .scaleEffect(ComboMoment.bumpScale(progress: progress ?? 1))
        }
        .alignmentGuide(.top) { _ in -inkCenter }
    }
}

#Preview("파티원 장 앞") {
    PlayerView(run: RunSamples.party, player: RunSamples.party.players[0], isPhoneReachable: true)
}

#Preview("파티원 장 뒤·콤보") {
    PlayerView(run: RunSamples.party, player: RunSamples.party.players[1], isPhoneReachable: true)
}

#Preview("파티원 장 멈춤") {
    PlayerView(run: RunSamples.party, player: RunSamples.party.players[2], isPhoneReachable: true)
}

#Preview("파티원 장 가장 긴 값") {
    PlayerView(run: RunSamples.playerEdges, player: RunSamples.playerEdges.players[0], isPhoneReachable: true)
}

#Preview("파티원 장 통지 전") {
    PlayerView(run: RunSamples.playerEdges, player: RunSamples.playerEdges.players[1], isPhoneReachable: true)
}

#Preview("파티원 장 격차 0·소식 늦음") {
    PlayerView(run: RunSamples.playerEdges, player: RunSamples.playerEdges.players[2], isPhoneReachable: true)
}

#Preview("파티원 장 서버 끊김") {
    PlayerView(run: RunSamples.serverLost, player: RunSamples.serverLost.players[0], isPhoneReachable: true)
}

#Preview("파티원 장 폰 끊김") {
    PlayerView(run: RunSamples.party, player: RunSamples.party.players[0], isPhoneReachable: false)
}

#Preview("파티원 장 내가 멈춤") {
    PlayerView(run: RunSamples.paused, player: RunSamples.paused.players[0], isPhoneReachable: true)
}
