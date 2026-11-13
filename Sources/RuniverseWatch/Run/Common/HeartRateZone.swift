import Foundation

/// 심박 구간 막대에 채울 칸 수(0~5)다. 최대 심박은 220 − 만 나이로 잡는다.
enum HeartRateZone {
    /// 생일이 없으면 nil(막대 숨김), 심박이 아직 없으면 0칸(빈 막대)이다.
    static func calculate(heartRateBpm: Int?, birthday: DateComponents?, today: DateComponents) -> Int? {
        guard let birthday else { return nil }
        guard let heartRateBpm else { return 0 }
        let age = gregorian.dateComponents([.year], from: birthday, to: today).year ?? 0
        let maxBpm = Double(maxHeartRateBaseBpm - age)
        return zoneLowerBoundFractions.count { Double(heartRateBpm) >= maxBpm * $0 }
    }

    /// 폰이 보낸 생일(`yyyy-MM-dd`)이다. 없거나 못 읽으면 nil이다.
    static func parseBirthday(_ value: String?) -> DateComponents? {
        let parts = value?.split(separator: "-", omittingEmptySubsequences: false) ?? []
        // Int는 `+1`도 읽어 자릿수와 숫자만 든 것을 먼저 본다
        guard parts.map(\.count) == [4, 2, 2], parts.allSatisfy({ $0.allSatisfy { ("0"..."9").contains($0) } }),
            let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        let birthday = DateComponents(year: year, month: month, day: day)
        return birthday.isValidDate(in: gregorian) ? birthday : nil
    }

    /// 오늘 날짜다. 만 나이를 생일과 같은 역법으로 센다.
    static func today() -> DateComponents {
        gregorian.dateComponents([.year, .month, .day], from: .now)
    }

    // 서버 생일은 양력인데 기기 달력은 다른 역법일 수 있다
    private static let gregorian = Calendar(identifier: .gregorian)

    // 경계는 화면에 안 보여 반올림하지 않고 그대로 비교한다
    private static let zoneLowerBoundFractions = [0.5, 0.6, 0.7, 0.8, 0.9]
    private static let maxHeartRateBaseBpm = 220
}
