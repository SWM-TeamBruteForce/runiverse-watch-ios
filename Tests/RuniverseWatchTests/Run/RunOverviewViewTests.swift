import Foundation
import Testing

@testable import RuniverseWatch

struct RunOverviewViewTests {

    // 만 30세라 최대 심박 190이고 148은 3구간이다
    private let today = DateComponents(year: 2025, month: 3, day: 10)

    @Test
    func `달리는 중엔 가운데에 지금 페이스를, 멈추면 멈춤을 쓴다`() {
        // when
        let running = content(RunSamples.party)
        let paused = content(RunSamples.paused)

        // then
        #expect(running.centerText == "5'32\"")
        #expect(!running.isPaused)
        #expect(paused.centerText == "멈춤")
        #expect(paused.isPaused)
    }

    @Test
    func `폰이 끊기면 받은 값과 파티원 사진을 흐리고, 격차 줄 대신 폰 안내를 띄운다`() {
        // when
        let content = content(RunSamples.party, isPhoneReachable: false)

        // then
        #expect(content.phoneValuesAlpha == 0.4)
        #expect(content.players.allSatisfy { $0.avatarAlpha == 0.4 })
        #expect(content.notice == "폰 연결 확인 중")
        #expect(!content.isGapRowShown)
    }

    @Test
    func `서버만 끊기면 내 값은 그대로 두고 파티원 사진만 흐리며 서버 안내를 띄운다`() {
        // when
        let content = content(RunSamples.serverLost)

        // then
        #expect(content.phoneValuesAlpha == 1)
        #expect(content.players.allSatisfy { $0.avatarAlpha == 0.4 })
        #expect(content.notice == "서버 연결 확인 중")
        #expect(!content.isGapRowShown)
    }

    @Test
    func `혼자면 서버가 끊겨도 흐릴 파티원이 없어 안내하지 않는다`() {
        // given
        let soloServerLost = RunState(
            runningRoomId: nil,
            type: .solo,
            status: .running,
            targetDistanceMeters: nil,
            isServerConnected: false,
            isPenaltyApplicable: false,
            me: RunSamples.solo.me,
            players: [],
            finish: nil,
            result: nil
        )

        // when & then
        #expect(content(soloServerLost).notice == nil)
    }

    @Test
    func `소식이 늦은 사람은 사진과 격차만 흐린다`() {
        // given
        let late = player(RunSamples.party.players[0], isStale: true)
        let run = runWithPlayers([late, RunSamples.party.players[1]])

        // when
        let players = content(run).players

        // then
        #expect(players[0].avatarAlpha == 0.4)
        #expect(players[0].gapAlpha == 0.4)
        #expect(players[1].avatarAlpha == 1)
        #expect(players[1].gapAlpha == 1)
    }

    @Test
    func `달리는 사람은 첫 글자와 격차를, 멈춤·끊김·마침인 사람은 상태 글자만 쓴다`() {
        // when
        let party = content(RunSamples.party).players
        let statuses = content(RunSamples.playerStatuses).players

        // then
        #expect(party[0].initial == "완")
        #expect(party[0].gapLabel == .gap(.ahead, FormattedDistance(value: "120", unit: .meter)))
        #expect(party[1].gapLabel == .gap(.behind, FormattedDistance(value: "20", unit: .meter)))
        #expect(statuses.map(\.initial) == [nil, nil, nil])
        #expect(statuses.map(\.gapLabel) == [.status("멈춤"), .status("끊김"), .status("마침")])
    }

    @Test
    func `멈춤·끊김·마침인 사람만 사진에 상태 아이콘을 얹는다`() {
        // when
        let running = content(RunSamples.party).players[0]
        let statuses = content(RunSamples.playerStatuses).players

        // then
        #expect(running.statusIcon == nil)
        #expect(statuses.map(\.statusIcon) == [.paused, .disconnected, .finished])
    }

    @Test
    func `그 사람 통지가 아직 없어 격차를 모르면 사진 아래를 비운다`() {
        // given
        let notNotified = player(RunSamples.party.players[0], gapMeters: nil)

        // when & then
        #expect(content(runWithPlayers([notNotified])).players[0].gapLabel == nil)
    }

    @Test
    func `콤보가 1 이상일 때만 사진에 고리를 두른다`() {
        // when
        let players = content(RunSamples.party).players

        // then -> 샘플은 두 번째 사람만 12콤보다
        #expect(players.map(\.isCombo) == [false, true, false])
    }

    @Test
    func `혼자면 심박을 쓰고, 심박이 없으면 --, 생일이 없으면 막대를 숨긴다`() {
        // when
        let measured = content(RunSamples.solo, heartRateBpm: 148)
        let unmeasured = content(RunSamples.solo, heartRateBpm: nil)
        let noBirthday = content(RunSamples.solo, heartRateBpm: 148, birthday: nil)

        // then
        #expect(measured.heartRateText == "148")
        #expect(measured.heartRateZone == 3)
        #expect(unmeasured.heartRateText == "--")
        #expect(unmeasured.heartRateZone == 0)
        #expect(noBirthday.heartRateZone == nil)
    }

    @Test
    func `목표가 없는 솔로는 링을 그리지 않는다`() {
        // when & then
        #expect(content(RunSamples.solo).progress == nil)
        #expect(content(RunSamples.party).progress != nil)
    }

    @Test
    func `단위를 줄이는 화면에선 격차 m는 숫자만 쓴다`() {
        // when
        let players = content(RunSamples.party, abbreviateGapUnits: true).players

        // then
        #expect(players[0].gapLabel == .gap(.ahead, FormattedDistance(value: "120", unit: nil)))
    }

    @Test(arguments: [(208.0, 248.0), (176, 215)])
    func `46mm·41mm는 가장 넓은 격차 셋이 링 안에 들어가 단위를 줄이지 않는다`(
        screenWidth: Double,
        screenHeight: Double
    ) {
        // when
        let slots = slots(screenWidth: screenWidth, screenHeight: screenHeight)

        // then
        #expect(!slots.abbreviateGapUnits)
    }

    @Test
    func `40mm는 가장 넓은 격차 셋이 링에 닿아 단위를 줄이고, 줄인 칸 셋은 링 안에 든다`() {
        // when
        let slots = slots(screenWidth: 162, screenHeight: 197)

        // then -> 맨 왼쪽 칸 시작이 글자 여백 12.5보다 안쪽이다
        #expect(slots.abbreviateGapUnits)
        #expect((162 - slots.playerCellWidth * 3) / 2 >= 12.5)
    }

    private func content(
        _ run: RunState,
        isPhoneReachable: Bool = true,
        heartRateBpm: Int? = 148,
        birthday: String? = RunSamples.birthday,
        abbreviateGapUnits: Bool = false
    ) -> RunOverviewContent {
        RunOverviewContent(
            run: run,
            isPhoneReachable: isPhoneReachable,
            heartRateBpm: heartRateBpm,
            birthday: birthday,
            today: today,
            abbreviateGapUnits: abbreviateGapUnits
        )
    }

    private func slots(screenWidth: Double, screenHeight: Double) -> RunOverviewSlots {
        let screen = WatchScreen(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            safeAreaTop: 40,
            safeAreaBottom: screenHeight - 20
        )
        return RunOverviewSlots(screen: screen, sizes: WatchFontSizes(screenWidth: screenWidth))
    }

    private func runWithPlayers(_ players: [Player]) -> RunState {
        let party = RunSamples.party
        return RunState(
            runningRoomId: party.runningRoomId,
            type: party.type,
            status: party.status,
            targetDistanceMeters: party.targetDistanceMeters,
            isServerConnected: party.isServerConnected,
            isPenaltyApplicable: party.isPenaltyApplicable,
            me: party.me,
            players: players,
            finish: nil,
            result: nil
        )
    }

    private func player(_ base: Player, gapMeters: Int? = 120, isStale: Bool = false) -> Player {
        Player(
            userId: base.userId,
            nickname: base.nickname,
            colorSlot: base.colorSlot,
            distanceMeters: base.distanceMeters,
            currentPaceSecondsPerKm: base.currentPaceSecondsPerKm,
            status: base.status,
            gapMeters: gapMeters,
            comboCount: base.comboCount,
            maxComboCount: base.maxComboCount,
            isStale: isStale
        )
    }
}
