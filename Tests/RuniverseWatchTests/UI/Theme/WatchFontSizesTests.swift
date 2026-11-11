import Testing

@testable import RuniverseWatch

struct WatchFontSizesTests {

    @Test(arguments: [208, 211, 195])
    func `46mm·울트라와 경계부터는 큰 단계 글자다`(screenWidth: Double) {
        // when
        let sizes = WatchFontSizes(screenWidth: screenWidth)

        // then
        #expect(sizes.bigNumber == 53)
        #expect(sizes.value == 18)
        #expect(sizes.reading == 14)
    }

    @Test(arguments: [187, 184, 176])
    func `42mm·SE 44mm·41mm는 작은 단계 글자다`(screenWidth: Double) {
        // when
        let sizes = WatchFontSizes(screenWidth: screenWidth)

        // then
        #expect(sizes.bigNumber == 47)
        #expect(sizes.value == 17)
        #expect(sizes.reading == 13)
    }

    @Test
    func `40mm는 작은 단계에서 큰 숫자만 더 줄인다`() {
        // when
        let sizes = WatchFontSizes(screenWidth: 162)

        // then
        #expect(sizes.bigNumber == 43)
        #expect(sizes.value == 17)
        #expect(sizes.reading == 13)
    }
}
