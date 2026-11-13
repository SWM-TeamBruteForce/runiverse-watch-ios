import Foundation
import Testing

@testable import RuniverseWatch

struct ComboBurstViewTests {

    @Test
    func `큰 순간은 콤보 수와 그 사람 첫 글자·이름·색을 그리고 한 문장으로 읽힌다`() {
        // given
        let player = RunSamples.party.players[1]
        let burst = ComboBurst(
            moment: ComboMoment(eventId: "e1", startedAt: Date()),
            userId: player.userId,
            comboCount: 10
        )

        // when
        let content = ComboBurstContent(burst: burst, player: player, photo: nil)

        // then
        #expect(content.countText == "10")
        #expect(content.word == "COMBO")
        #expect(content.initial == "콩")
        #expect(content.nickname == "콩나물")
        #expect(content.colorSlot == 2)
        #expect(content.accessibilityLabel == "10 COMBO 콩나물")
    }

    @Test
    func `큰 순간은 그 사람 사진이 있으면 첫 글자 대신 사진을 그린다`() throws {
        // given
        let player = RunSamples.party.players[1]
        let photo = try #require(RunSamples.brightPhotos[player.userId])
        let burst = ComboBurst(
            moment: ComboMoment(eventId: "e1", startedAt: Date()),
            userId: player.userId,
            comboCount: 10
        )

        // when
        let content = ComboBurstContent(burst: burst, player: player, photo: photo)

        // then
        #expect(content.photo == photo)
        #expect(content.initial == nil)
    }
}
