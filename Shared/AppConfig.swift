import Foundation

enum AppConfig {
    static let appGroup = "group.com.mtbsteve.solaredge"
    static let keychainService = "com.mtbsteve.solaredge.ha"
    static let keychainAccessGroup = "com.mtbsteve.solaredge"

    static let batterySlotCount = 4

    enum DefaultEntity {
        static let solarPower = "sensor.solaredgecloud_solar_power"
        static let gridPower = "sensor.solaredgecloud_grid_power"
        static let consumption = "sensor.solaredgecloud_power_consumption"
    }

    enum SharedKey {
        static let baseURL = "ha.baseURL"
        static let lastSnapshot = "ha.lastSnapshot"
        static let solarPowerEntity = "entity.solarPower"
        static let gridPowerEntity = "entity.gridPower"
        static let consumptionEntity = "entity.consumption"
        static func batteryEntity(_ slot: Int) -> String { "entity.batt.\(slot)" }
    }

    static let refreshInterval: TimeInterval = 5 * 60
    static let historyHours: Int = 24

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    // MARK: - Configurable entities

    static var solarPowerEntity: String {
        nonEmpty(sharedDefaults.string(forKey: SharedKey.solarPowerEntity)) ?? DefaultEntity.solarPower
    }
    static var gridPowerEntity: String {
        nonEmpty(sharedDefaults.string(forKey: SharedKey.gridPowerEntity)) ?? DefaultEntity.gridPower
    }
    static var consumptionEntity: String {
        nonEmpty(sharedDefaults.string(forKey: SharedKey.consumptionEntity)) ?? DefaultEntity.consumption
    }

    /// Returns the configured battery entities (1-based slots), preserving slot order.
    /// Empty/missing slots are returned as nil so callers can keep slot indexing.
    static var batteryEntitySlots: [String?] {
        (1...batterySlotCount).map { slot in
            nonEmpty(sharedDefaults.string(forKey: SharedKey.batteryEntity(slot)))
        }
    }

    /// Just the configured (non-empty) battery entity ids, in slot order.
    static var configuredBatteryEntities: [String] {
        batteryEntitySlots.compactMap { $0 }
    }

    private static func nonEmpty(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return s
    }
}
