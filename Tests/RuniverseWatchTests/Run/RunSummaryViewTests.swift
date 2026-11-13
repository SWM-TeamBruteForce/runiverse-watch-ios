import Testing

@testable import RuniverseWatch

struct RunSummaryViewTests {

    private static let appleScreens = [
        WatchScreen(screenWidth: 211, screenHeight: 257, safeAreaTop: 56.5, safeAreaBottom: 217),
        WatchScreen(screenWidth: 205, screenHeight: 251, safeAreaTop: 55, safeAreaBottom: 212),
        WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212),
        WatchScreen(screenWidth: 198, screenHeight: 242, safeAreaTop: 51, safeAreaBottom: 215),
        WatchScreen(screenWidth: 187, screenHeight: 223, safeAreaTop: 48, safeAreaBottom: 192),
        WatchScreen(screenWidth: 176, screenHeight: 215, safeAreaTop: 46, safeAreaBottom: 189),
        WatchScreen(screenWidth: 162, screenHeight: 197, safeAreaTop: 40, safeAreaBottom: 171),
    ]

    @Test
    func `제목부터 시간·평균 페이스까지를 안전 영역 위 끝과 닫기 버튼 사이 가운데에 둔다`() {
        // given -> 46mm 시뮬레이터에서 잰 화면이다
        let screen = WatchScreen(screenWidth: 208, screenHeight: 248, safeAreaTop: 53, safeAreaBottom: 212)
        let sizes = WatchFontSizes(screenWidth: screen.screenWidth)

        // when
        let slots = RunSummarySlots(screen: screen, sizes: sizes)

        // then -> 버튼 윗변 248 − 8 − 48, 묶음은 제목 12.488 + 18 + 총거리 38.266 + 18 + 시간 12.996
        #expect(slots.closeButtonTop == 192)
        #expect(abs(slots.titleBottom - 85.113) < 0.001)
        #expect(abs(slots.bigNumberBaseline - 141.379) < 0.001)
        #expect(abs(slots.timePaceRowTop - 159.379) < 0.001)
    }

    @Test(arguments: appleScreens)
    func `묶음은 어느 화면에서도 안전 영역 안에서 시작해 닫기 버튼 위에서 끝난다`(screen: WatchScreen) {
        // given
        let sizes = WatchFontSizes(screenWidth: screen.screenWidth)
        let hangulInk = SUITFont.hangulInk

        // when
        let slots = RunSummarySlots(screen: screen, sizes: sizes)

        // then
        let titleTop = slots.titleBottom - sizes.reading * (hangulInk.aboveBaselineEm + hangulInk.belowBaselineEm)
        let timePaceRowBottom = slots.timePaceRowTop + sizes.value * SUITFont.numeralInk.aboveBaselineEm
        #expect(titleTop > screen.safeAreaTop)
        #expect(timePaceRowBottom < slots.closeButtonTop)
    }

    @Test
    func `총거리·시간·평균 페이스를 보인다`() {
        // when
        let content = RunSummaryContent(result: RunSamples.result, isPhoneReachable: true)

        // then
        #expect(content.distanceText == "5.02")
        #expect(content.elapsedTimeText == "28:41")
        #expect(content.averagePaceText == "5'43\"")
    }

    @Test
    func `결과를 받는 동안은 값 자리에 모름 표시를 보인다`() {
        // when
        let content = RunSummaryContent(result: nil, isPhoneReachable: true)

        // then
        #expect(content.title == "러닝 완료")
        #expect(content.distanceText == "--")
        #expect(content.elapsedTimeText == "--")
        #expect(content.averagePaceText == "--")
    }

    @Test
    func `결과를 받는 중 폰이 끊기면 폰 연결 확인 중을 보이고 값을 흐린다`() {
        // when
        let content = RunSummaryContent(result: nil, isPhoneReachable: false)

        // then
        #expect(content.isResultStuck)
        #expect(content.title == "폰 연결 확인 중")
        #expect(content.valuesAlpha == RunDimensions.staleContentAlpha)
    }

    @Test
    func `결과를 받는 중이라도 폰이 연결돼 있으면 멈춘 것으로 보지 않는다`() {
        // when
        let content = RunSummaryContent(result: nil, isPhoneReachable: true)

        // then
        #expect(!content.isResultStuck)
        #expect(content.valuesAlpha == 1)
    }

    @Test
    func `받은 결과가 있으면 폰이 끊겨도 러닝 완료를 보이고 흐리지 않는다`() {
        // when
        let content = RunSummaryContent(result: RunSamples.result, isPhoneReachable: false)

        // then
        #expect(!content.isResultStuck)
        #expect(content.title == "러닝 완료")
        #expect(content.valuesAlpha == 1)
    }

    @Test
    func `닫기 버튼 문구를 쓴다`() {
        // when
        let content = RunSummaryContent(result: RunSamples.result, isPhoneReachable: true)

        // then
        #expect(content.closeLabel == "닫기")
    }
}
