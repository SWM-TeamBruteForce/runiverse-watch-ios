/// 거리·격차·페이스·시간 표기와 목표 진행률이다.
enum RunFormat {
    static let unknownPace = "--'--\""

    /// 완주 전에 목표 숫자가 먼저 뜨지 않게 버린다. 10km부터는 위 줄에 들어가게 한 자리만 쓴다.
    static func formatRunDistanceKm(_ meters: Int) -> String {
        let km = meters / metersPerKm
        let remainderMeters = meters % metersPerKm
        if meters < extraDecimalBelowMeters {
            return "\(km).\(padTwoDigits(remainderMeters / metersPerHundredthKm))"
        }
        return "\(km).\(remainderMeters / metersPerTenthKm)"
    }

    /// 파티원과의 격차다. 1000m 미만은 m, 10km 미만은 소수 한 자리 km, 그 위는 정수 km로 버린다.
    /// `abbreviateUnits`면 m는 숫자만, km는 `k`로 줄인다 — 단위를 다 빼면 42m와 42km가 같아 보인다.
    static func formatGapDistance(_ gapMeters: Int, abbreviateUnits: Bool) -> FormattedDistance {
        let meters = Int(clamping: gapMeters.magnitude)
        if meters < metersPerKm {
            return FormattedDistance(value: "\(meters)", unit: abbreviateUnits ? nil : .meter)
        }
        let km = meters / metersPerKm
        let kilometerLabel: DistanceUnitLabel = abbreviateUnits ? .shortKilometer : .kilometer
        if meters >= extraDecimalBelowMeters {
            return FormattedDistance(value: "\(km)", unit: kilometerLabel)
        }
        let tenthsOfKm = meters % metersPerKm / metersPerTenthKm
        return FormattedDistance(value: "\(km).\(tenthsOfKm)", unit: kilometerLabel)
    }

    /// 목표까지 남은 거리다. 1000m 미만은 m, 그 위는 소수 한 자리 km다.
    /// 남은 거리를 적게 말하지 않게 폰처럼 올린다.
    static func formatRemainingDistance(_ meters: Int) -> FormattedDistance {
        if meters < metersPerKm {
            return FormattedDistance(value: "\(meters)", unit: .meter)
        }
        let tenthsOfKm = (meters + metersPerTenthKm - 1) / metersPerTenthKm
        return FormattedDistance(value: "\(tenthsOfKm / 10).\(tenthsOfKm % 10)", unit: .kilometer)
    }

    /// 위치를 못 잡았거나 60분을 넘으면 낼 페이스가 없다고 본다.
    static func formatPace(_ secondsPerKm: Int?) -> String {
        guard let secondsPerKm, secondsPerKm < secondsPerHour else { return unknownPace }
        return "\(secondsPerKm / 60)'\(padTwoDigits(secondsPerKm % 60))\""
    }

    /// 1시간 전엔 폰처럼 `mm:ss`, 넘으면 `h:mm:ss`다.
    static func formatElapsedTime(_ seconds: Int) -> String {
        let rest = padTwoDigits(seconds % 60)
        if seconds < secondsPerHour {
            return "\(padTwoDigits(seconds / 60)):\(rest)"
        }
        return "\(seconds / secondsPerHour):\(padTwoDigits(seconds / 60 % 60)):\(rest)"
    }

    /// 목표까지 진행률이다. 목표가 없으면(솔로) nil — 링을 그리지 않는다.
    static func distanceProgress(_ distanceMeters: Int, targetDistanceMeters: Int?) -> Double? {
        guard let targetDistanceMeters, targetDistanceMeters > 0 else { return nil }
        return Double(distanceMeters) / Double(targetDistanceMeters)
    }

    private static func padTwoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    private static let metersPerKm = 1000
    private static let metersPerTenthKm = 100
    private static let metersPerHundredthKm = 10
    private static let extraDecimalBelowMeters = 10_000
    private static let secondsPerHour = 3600
}

/// 표기를 마친 거리다. 숫자와 단위를 따로 그린다 — 단위는 작고 흐리게 쓴다.
struct FormattedDistance: Equatable {
    let value: String
    /// 줄여서 숫자만 쓰면 없다.
    let unit: DistanceUnitLabel?
}

/// `km`와 `k`는 다른 단위가 아니라 같은 단위의 다른 표기다.
enum DistanceUnitLabel {
    case meter
    case kilometer
    case shortKilometer
}

extension Player {
    /// 폰이나 서버가 끊겼거나 그 사람 소식이 늦으면 그 사람 값은 오래된 값이다.
    func hasStaleValues(in run: RunState, isPhoneReachable: Bool) -> Bool {
        !isPhoneReachable || !run.isServerConnected || isStale
    }

    /// 멈췄거나 끊긴 사람은 지금 페이스가 없다 — 폰은 마지막 값을 그대로 보낸다.
    var shownPaceSecondsPerKm: Int? {
        switch status {
        case .paused, .disconnected: nil
        case .running, .finished: currentPaceSecondsPerKm
        }
    }
}

extension RunState {
    /// 내가 버튼으로 멈춰도 상대처럼 지금 페이스가 없다.
    var shownMyPaceSecondsPerKm: Int? {
        status == .paused ? nil : me.currentPaceSecondsPerKm
    }
}

enum GapDirection {
    case ahead
    case behind
    case level

    /// `gapMeters`는 상대 − 나라서 양수면 상대가 앞이다.
    init(gapMeters: Int) {
        if gapMeters > 0 {
            self = .ahead
        } else if gapMeters < 0 {
            self = .behind
        } else {
            self = .level
        }
    }
}
