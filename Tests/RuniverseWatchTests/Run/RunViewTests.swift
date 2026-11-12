import Testing

@testable import RuniverseWatch

struct RunViewTests {

    private let players = RunSamples.party.players

    @Test
    func `파티원이 없으면 세로 점을 그리지 않는다`() {
        // when & then
        #expect(VerticalPageDotsContent(players: [], verticalPage: .overview) == nil)
    }

    @Test
    func `세로 점은 첫 화면과 파티원 수만큼이고 첫 화면이면 첫 점이다`() {
        // when
        let dots = VerticalPageDotsContent(players: players, verticalPage: .overview)

        // then
        #expect(dots?.count == 4)
        #expect(dots?.currentIndex == 0)
    }

    @Test
    func `파티원 장이면 명단 순서 다음 점을 가리킨다`() {
        // when
        let dots = VerticalPageDotsContent(players: players, verticalPage: .player(userId: players[1].userId))

        // then
        #expect(dots?.currentIndex == 2)
    }

    @Test
    func `보던 파티원이 명단에서 빠지면 첫 점을 가리킨다`() {
        // when
        let dots = VerticalPageDotsContent(players: players, verticalPage: .player(userId: "left"))

        // then
        #expect(dots?.currentIndex == 0)
    }
}
