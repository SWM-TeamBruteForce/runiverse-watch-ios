import Foundation
import Testing

@testable import RuniverseWatch

struct MyRecordViewTests {

    // 만 30세라 최대 심박 190이고 148은 3구간이다
    private let today = DateComponents(year: 2025, month: 3, day: 10)

    @Test
    func `달리는 중엔 위 줄 안내가 없고, 멈추면 멈춤을 쓴다`() {
        // when & then
        #expect(content(RunSamples.party).topNotice == nil)
        #expect(content(RunSamples.paused).topNotice == "멈춤")
    }

    @Test
    func `멈춘 채 폰이 끊기면 같은 자리라 끊김 안내가 먼저다`() {
        // when
        let content = content(RunSamples.paused, isPhoneReachable: false)

        // then
        #expect(content.topNotice == "폰 연결 확인 중")
        #expect(content.phoneValuesAlpha == 0.4)
    }

    @Test
    func `폰이 아직 안 보낸 케이던스·칼로리는 --로 쓴다`() {
        // given
        let me = MyRecord(
            distanceMeters: 0,
            elapsedSeconds: 0,
            currentPaceSecondsPerKm: nil,
            caloriesKcal: nil,
            cadenceSpm: nil
        )
        let run = RunState(
            runningRoomId: nil,
            type: .solo,
            status: .running,
            targetDistanceMeters: nil,
            isServerConnected: true,
            isPenaltyApplicable: false,
            me: me,
            players: [],
            finish: nil,
            result: nil
        )

        // when
        let content = content(run)

        // then
        #expect(content.cadenceText == "--")
        #expect(content.caloriesText == "--")
    }

    @Test
    func `심박과 구간은 첫 화면 솔로와 같게 쓴다`() {
        // when
        let measured = content(RunSamples.party, heartRateBpm: 148)
        let noBirthday = content(RunSamples.party, heartRateBpm: 148, birthday: nil)

        // then
        #expect(measured.heartRateText == "148")
        #expect(measured.heartRateZone == 3)
        #expect(noBirthday.heartRateZone == nil)
    }

    @Test
    func `막대가 있으면 케이던스 줄은 막대 아래, 없으면 심박 바로 아래에서 묶음 간격만큼 띄운다`() {
        // given
        let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)
        let sizes = WatchFontSizes(screenWidth: 208)

        // when
        let withBar = MyRecordSlots(screen: screen, sizes: sizes, showsZoneBar: true)
        let withoutBar = MyRecordSlots(screen: screen, sizes: sizes, showsZoneBar: false)

        // then -> 막대 사이 4 + 막대 3만큼 차이 난다
        #expect(abs(withBar.recordRowsTop - (withBar.zoneBarTop + 3 + 18)) < 0.001)
        #expect(abs(withoutBar.recordRowsTop - (withoutBar.heartRateBottom + 18)) < 0.001)
        #expect(abs(withBar.recordRowsTop - withoutBar.recordRowsTop - 7) < 0.001)
    }

    @Test
    func `46mm·41mm는 케이던스·칼로리를 한 줄에, 40mm는 두 줄에 둔다`() {
        // given -> 각 시뮬레이터에서 잰 화면이다
        let screens = [
            WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212),
            WatchScreen(screenWidth: 176, screenHeight: 215, safeAreaTop: 46, safeAreaBottom: 189),
            WatchScreen(screenWidth: 162, screenHeight: 197, safeAreaTop: 40, safeAreaBottom: 178),
        ]

        // when
        let fitsOneLine = screens.map {
            MyRecordSlots(screen: $0, sizes: WatchFontSizes(screenWidth: $0.screenWidth), showsZoneBar: true)
                .recordsFitOneLine
        }

        // then
        #expect(fitsOneLine == [true, true, false])
    }

    private func content(
        _ run: RunState,
        isPhoneReachable: Bool = true,
        heartRateBpm: Int? = 148,
        birthday: String? = RunSamples.birthday
    ) -> MyRecordContent {
        MyRecordContent(
            run: run,
            isPhoneReachable: isPhoneReachable,
            heartRateBpm: heartRateBpm,
            birthday: birthday,
            today: today
        )
    }
}
