import Testing

@testable import RuniverseWatch

struct PlayerViewTests {

    @Test
    func `파티원 이름과 거리, 그 사람 진행을 보인다`() {
        // when
        let content = content(player(gapMeters: 120))

        // then
        #expect(content.nickname == "완두콩")
        #expect(content.distanceText == "3.54")
        #expect(content.progress == 3541.0 / 5000)
        #expect(content.colorSlot == 1)
    }

    @Test
    func `격차가 양수면 앞, 음수면 뒤를 숫자 앞에 쓴다`() {
        // when
        let ahead = content(player(gapMeters: 120)).center
        let behind = content(player(gapMeters: -1299)).center

        // then
        #expect(ahead == .gap(directionWord: "앞", distance: FormattedDistance(value: "120", unit: .meter)))
        #expect(behind == .gap(directionWord: "뒤", distance: FormattedDistance(value: "1.2", unit: .kilometer)))
    }

    @Test
    func `격차가 0이면 앞뒤 없이 0m를 쓴다`() {
        // when & then
        #expect(
            content(player(gapMeters: 0)).center
                == .gap(directionWord: nil, distance: FormattedDistance(value: "0", unit: .meter))
        )
    }

    @Test
    func `그 사람 통지가 아직 없으면 격차를 --m로 쓴다`() {
        // when & then
        #expect(
            content(player(gapMeters: nil)).center
                == .gap(directionWord: nil, distance: FormattedDistance(value: "--", unit: .meter))
        )
    }

    @Test(arguments: [(RunStatus.paused, "멈춤"), (.disconnected, "끊김"), (.finished, "마침")])
    func `멈췄거나 끊겼거나 마친 파티원은 격차 대신 상태를 쓴다`(status: RunStatus, word: String) {
        // when & then
        #expect(content(player(gapMeters: 120, status: status)).center == .status(word))
    }

    @Test
    func `상대와 내 지금 페이스를 쓴다`() {
        // when
        let content = content(player(gapMeters: 120))

        // then
        #expect(content.playerPaceText == "5'18\"")
        #expect(content.myPaceText == "5'32\"")
    }

    @Test(arguments: [RunStatus.paused, .disconnected])
    func `멈췄거나 끊긴 파티원은 페이스를 비운다`(status: RunStatus) {
        // when & then
        #expect(content(player(gapMeters: 120, status: status)).playerPaceText == "--'--\"")
    }

    @Test
    func `마친 파티원은 마지막 페이스를 남긴다`() {
        // when & then
        #expect(content(player(gapMeters: 120, status: .finished)).playerPaceText == "5'18\"")
    }

    @Test
    func `내가 멈추면 내 페이스를 비운다`() {
        // when
        let content = PlayerContent(
            run: RunSamples.paused,
            player: RunSamples.paused.players[0],
            isPhoneReachable: true
        )

        // then
        #expect(content.myPaceText == "--'--\"")
    }

    @Test
    func `콤보 중이면 지금 콤보를, 아니면 최고 콤보를 쓴다`() {
        // when
        let combo = content(player(gapMeters: 120, comboCount: 12)).bottomLabel
        let noCombo = content(player(gapMeters: 120, comboCount: 0)).bottomLabel

        // then
        #expect(combo == .combo("12콤보"))
        #expect(noCombo == .combo("최고 20"))
    }

    @Test
    func `폰이 끊기면 상대 페이스와 콤보 대신 폰 안내를 띄우고 내 페이스까지 흐린다`() {
        // when
        let content = content(player(gapMeters: 120, comboCount: 12), isPhoneReachable: false)

        // then
        #expect(content.playerPaceText == nil)
        #expect(content.bottomLabel == .notice("폰 연결 확인 중"))
        #expect(content.playerValuesAlpha == 0.4)
        #expect(content.phoneValuesAlpha == 0.4)
    }

    @Test
    func `서버만 끊기면 그 사람 값만 흐리고 서버 안내를 띄운다`() {
        // when
        let content = PlayerContent(
            run: RunSamples.serverLost,
            player: RunSamples.serverLost.players[0],
            isPhoneReachable: true
        )

        // then
        #expect(content.playerPaceText == nil)
        #expect(content.bottomLabel == .notice("서버 연결 확인 중"))
        #expect(content.playerValuesAlpha == 0.4)
        #expect(content.phoneValuesAlpha == 1)
    }

    @Test
    func `그 사람 소식만 늦으면 안내 없이 그 사람 값만 흐린다`() {
        // when
        let content = content(player(gapMeters: 120, isStale: true))

        // then
        #expect(content.playerPaceText == "5'18\"")
        #expect(content.bottomLabel == .combo("최고 20"))
        #expect(content.playerValuesAlpha == 0.4)
        #expect(content.phoneValuesAlpha == 1)
    }

    @Test
    func `46mm는 가장 넓은 두 페이스가 한 줄에 들어가고 콤보는 맨 아래 줄 자리에 둔다`() {
        // given -> 46mm 시뮬레이터에서 잰 화면이다
        let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)
        let sizes = WatchFontSizes(screenWidth: screen.screenWidth)

        // when
        let slots = PlayerSlots(screen: screen, sizes: sizes)

        // then
        #expect(slots.pacesFitOneLine)
        #expect(slots.comboRowTop == RunPageSlots(screen: screen, sizes: sizes).bottomRowTop)
    }

    @Test(arguments: [
        (WatchScreen(screenWidth: 176, screenHeight: 215, safeAreaTop: 46, safeAreaBottom: 189), 174.081),
        (WatchScreen(screenWidth: 162, screenHeight: 197, safeAreaTop: 40, safeAreaBottom: 178), 164.137),
    ])
    func `41·40mm는 페이스를 두 줄로 쓰고 콤보를 그 아래 줄 간격만큼 내린다`(screen: WatchScreen, comboRowTop: Double) {
        // given
        let sizes = WatchFontSizes(screenWidth: screen.screenWidth)

        // when
        let slots = PlayerSlots(screen: screen, sizes: sizes)

        // then -> 아래 줄 윗변 133.661·123.717에서 두 줄(17pt 숫자 12.274 + 라벨 꼬리 0.936씩)과 줄 간격 7 둘만큼 내려간다
        #expect(!slots.pacesFitOneLine)
        #expect(abs(slots.comboRowTop - comboRowTop) < 0.001)
    }

    @Test
    func `나올 수 있는 모든 페이스가 페이스 칸에 들어간다`() {
        // given -> 60분부터와 위치 없음은 모두 `--'--"`라 0초부터 59분 59초까지와 그 하나를 본다
        let sizes = WatchFontSizes(screenWidth: 208)
        let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)
        let labelSize = WatchFontSizes.supporting
        let labelWidth = SUITFont.width(of: "상대", size: labelSize, weight: .medium) + PlayerSlots.labelToPaceGap
        let myLabelWidth = SUITFont.width(of: "나", size: labelSize, weight: .medium) + PlayerSlots.labelToPaceGap
        let paces = (0..<3600).map { RunFormat.formatPace($0) } + [RunFormat.unknownPace]

        // when
        let slots = PlayerSlots(screen: screen, sizes: sizes)

        // then -> 상대는 원래 폭, 나는 같은 폭 숫자로 잰다
        let widestPlayerPace = paces.map { SUITFont.width(of: $0, size: sizes.value, weight: .semiBold) }.max() ?? 0
        let widestMyPace =
            paces.map {
                SUITFont.width(of: $0, size: sizes.value, weight: .semiBold, monospacesDigits: true)
            }
            .max() ?? 0
        #expect(labelWidth + widestPlayerPace <= slots.playerPaceCellWidth + 0.001)
        #expect(myLabelWidth + widestMyPace <= slots.myPaceCellWidth + 0.001)
    }

    private func content(_ player: Player, isPhoneReachable: Bool = true) -> PlayerContent {
        PlayerContent(run: RunSamples.party, player: player, isPhoneReachable: isPhoneReachable)
    }

    private func player(
        gapMeters: Int?,
        status: RunStatus = .running,
        comboCount: Int = 0,
        isStale: Bool = false
    ) -> Player {
        Player(
            userId: "u1",
            nickname: "완두콩",
            colorSlot: 1,
            distanceMeters: 3541,
            currentPaceSecondsPerKm: 318,
            status: status,
            gapMeters: gapMeters,
            comboCount: comboCount,
            maxComboCount: 20,
            isStale: isStale
        )
    }
}
