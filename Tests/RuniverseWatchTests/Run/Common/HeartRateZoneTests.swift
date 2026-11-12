import Foundation
import Testing

@testable import RuniverseWatch

struct HeartRateZoneTests {

    // 만 30세라 최대 심박은 190이고 구간 경계는 95·114·133·152·171이다
    private let birthday = DateComponents(year: 1995, month: 3, day: 10)
    private let today = DateComponents(year: 2025, month: 3, day: 10)

    @Test
    func `최대 심박의 50% 미만이면 0칸이다`() {
        // when & then
        #expect(HeartRateZone.calculate(heartRateBpm: 94, birthday: birthday, today: today) == 0)
    }

    @Test
    func `경계와 같으면 그 구간으로 센다`() {
        // when & then
        #expect(HeartRateZone.calculate(heartRateBpm: 95, birthday: birthday, today: today) == 1)
        #expect(HeartRateZone.calculate(heartRateBpm: 133, birthday: birthday, today: today) == 3)
        #expect(HeartRateZone.calculate(heartRateBpm: 171, birthday: birthday, today: today) == 5)
    }

    @Test
    func `경계는 반올림하지 않는다`() {
        // given -> 만 29세, 최대 심박 191이라 60% 경계는 114.6이다
        let beforeBirthday = DateComponents(year: 2025, month: 3, day: 9)

        // when & then
        #expect(HeartRateZone.calculate(heartRateBpm: 114, birthday: birthday, today: beforeBirthday) == 1)
        #expect(HeartRateZone.calculate(heartRateBpm: 115, birthday: birthday, today: beforeBirthday) == 2)
    }

    @Test
    func `2월 29일생은 윤년이 아닌 해 3월 1일에 나이를 먹는다`() {
        // given -> 만 28세면 최대 심박 192라 50% 경계는 96, 만 29세면 191이라 95.5다
        let leapDayBirthday = DateComponents(year: 1996, month: 2, day: 29)
        let february28 = DateComponents(year: 2025, month: 2, day: 28)
        let march1 = DateComponents(year: 2025, month: 3, day: 1)

        // when & then
        #expect(HeartRateZone.calculate(heartRateBpm: 95, birthday: leapDayBirthday, today: february28) == 0)
        #expect(HeartRateZone.calculate(heartRateBpm: 96, birthday: leapDayBirthday, today: march1) == 1)
        #expect(HeartRateZone.calculate(heartRateBpm: 95, birthday: leapDayBirthday, today: march1) == 0)
    }

    @Test
    func `생일이 없으면 심박이 있어도 막대를 숨긴다`() {
        // when & then
        #expect(HeartRateZone.calculate(heartRateBpm: 133, birthday: nil, today: today) == nil)
        #expect(HeartRateZone.calculate(heartRateBpm: nil, birthday: nil, today: today) == nil)
    }

    @Test
    func `생일이 있으면 심박이 없을 땐 빈 막대, 있으면 그 구간이다`() {
        // when & then
        #expect(HeartRateZone.calculate(heartRateBpm: nil, birthday: birthday, today: today) == 0)
        #expect(HeartRateZone.calculate(heartRateBpm: 133, birthday: birthday, today: today) == 3)
    }

    @Test
    func `생일은 yyyy-MM-dd로 읽고, 없거나 깨졌으면 nil이다`() {
        // when & then
        #expect(HeartRateZone.parseBirthday("1995-03-10") == DateComponents(year: 1995, month: 3, day: 10))
        #expect(HeartRateZone.parseBirthday(nil) == nil)
        #expect(HeartRateZone.parseBirthday("1995/03/10") == nil)
        #expect(HeartRateZone.parseBirthday("1995-3-10") == nil)
        #expect(HeartRateZone.parseBirthday("1995-+3-10") == nil)
        #expect(HeartRateZone.parseBirthday("1995-02-30") == nil)
    }
}
