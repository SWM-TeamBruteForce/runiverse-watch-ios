import Foundation

/// 장끼리 같이 쓰는 문구다.
enum RunTexts {
    static let valueUnknown = String(localized: "run_value_unknown", bundle: .module)
    static let paused = String(localized: "run_status_paused", bundle: .module)
    static let kilometerUnit = String(localized: "unit_km", bundle: .module)
    static let heartRateUnit = String(localized: "unit_bpm", bundle: .module)
    static let cadenceUnit = String(localized: "unit_spm", bundle: .module)
    static let caloriesUnit = String(localized: "unit_kcal", bundle: .module)

    /// 어디와의 연결을 확인 중인지만 쓴다. 서버만 끊기면 흐릴 파티원이 있을 때만 알린다.
    static func connectionNotice(run: RunState, isPhoneReachable: Bool) -> String? {
        if !isPhoneReachable { return String(localized: "run_phone_checking", bundle: .module) }
        if !run.isServerConnected, !run.players.isEmpty {
            return String(localized: "run_server_checking", bundle: .module)
        }
        return nil
    }

    static func statusWord(_ status: RunStatus) -> String? {
        switch status {
        case .paused: paused
        case .disconnected: String(localized: "run_status_disconnected", bundle: .module)
        case .finished: String(localized: "run_status_finished", bundle: .module)
        case .running: nil
        }
    }

    static func distanceUnit(_ unit: DistanceUnitLabel?) -> String? {
        switch unit {
        case .meter: String(localized: "unit_m", bundle: .module)
        case .kilometer: kilometerUnit
        case .shortKilometer: String(localized: "unit_short_km", bundle: .module)
        case nil: nil
        }
    }
}
