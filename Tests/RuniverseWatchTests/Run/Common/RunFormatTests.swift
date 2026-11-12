import Testing

@testable import RuniverseWatch

struct RunFormatTests {

    @Test
    func `내 거리는 10km 전까지 소수 둘째 자리로 버린다`() {
        // when & then
        #expect(RunFormat.formatRunDistanceKm(3429) == "3.42")
        #expect(RunFormat.formatRunDistanceKm(4999) == "4.99")
        #expect(RunFormat.formatRunDistanceKm(55) == "0.05")
        #expect(RunFormat.formatRunDistanceKm(9999) == "9.99")
    }

    @Test
    func `내 거리는 10km부터 소수 한 자리로 버린다`() {
        // when & then
        #expect(RunFormat.formatRunDistanceKm(10_000) == "10.0")
        #expect(RunFormat.formatRunDistanceKm(42_195) == "42.1")
    }

    @Test
    func `격차는 1000m 미만이면 m로 쓴다`() {
        // when & then
        #expect(gap(120) == FormattedDistance(value: "120", unit: .meter))
        #expect(gap(-20) == FormattedDistance(value: "20", unit: .meter))
        #expect(gap(0) == FormattedDistance(value: "0", unit: .meter))
        #expect(gap(999) == FormattedDistance(value: "999", unit: .meter))
    }

    @Test
    func `격차는 10km 미만이면 소수 한 자리 km, 그 위는 정수 km로 버린다`() {
        // when & then
        #expect(gap(1000) == FormattedDistance(value: "1.0", unit: .kilometer))
        #expect(gap(1299) == FormattedDistance(value: "1.2", unit: .kilometer))
        #expect(gap(-9999) == FormattedDistance(value: "9.9", unit: .kilometer))
        #expect(gap(10_000) == FormattedDistance(value: "10", unit: .kilometer))
        #expect(gap(42_195) == FormattedDistance(value: "42", unit: .kilometer))
    }

    @Test
    func `격차가 양수면 상대가 앞, 음수면 뒤, 0이면 나란히다`() {
        // when & then
        #expect(GapDirection(gapMeters: 120) == .ahead)
        #expect(GapDirection(gapMeters: -20) == .behind)
        #expect(GapDirection(gapMeters: 0) == .level)
    }

    @Test
    func `페이스는 분과 초로 쓰고, 없거나 60분을 넘으면 비운다`() {
        // when & then
        #expect(RunFormat.formatPace(332) == "5'32\"")
        #expect(RunFormat.formatPace(605) == "10'05\"")
        #expect(RunFormat.formatPace(3599) == "59'59\"")
        #expect(RunFormat.formatPace(3600) == RunFormat.unknownPace)
        #expect(RunFormat.formatPace(nil) == RunFormat.unknownPace)
    }

    @Test
    func `시간은 1시간 전엔 mm:ss, 넘으면 h:mm:ss다`() {
        // when & then
        #expect(RunFormat.formatElapsedTime(5) == "00:05")
        #expect(RunFormat.formatElapsedTime(1450) == "24:10")
        #expect(RunFormat.formatElapsedTime(3599) == "59:59")
        #expect(RunFormat.formatElapsedTime(3600) == "1:00:00")
        #expect(RunFormat.formatElapsedTime(17_999) == "4:59:59")
    }

    @Test
    func `목표가 있으면 진행률을 주고, 없으면 nil이다`() {
        // when & then -> 0m여도 빈 링을 그리도록 nil이 아니라 0이다
        #expect(RunFormat.distanceProgress(0, targetDistanceMeters: 5000) == 0)
        #expect(RunFormat.distanceProgress(2500, targetDistanceMeters: 5000) == 0.5)
        #expect(RunFormat.distanceProgress(2500, targetDistanceMeters: nil) == nil)
        #expect(RunFormat.distanceProgress(2500, targetDistanceMeters: 0) == nil)
    }

    private func gap(_ gapMeters: Int) -> FormattedDistance {
        RunFormat.formatGapDistance(gapMeters, abbreviateUnits: false)
    }
}
