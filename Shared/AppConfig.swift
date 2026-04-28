import Foundation

enum AppConfig {
    static let appGroup = "group.com.mtbsteve.solaredge"
    static let keychainService = "com.mtbsteve.solaredge.ha"
    static let keychainAccessGroup = "com.mtbsteve.solaredge"

    static let invWestEntity = "sensor.solaredge_i1_ac_power"
    static let invEastEntity = "sensor.solaredge_i3_ac_power"
    static let batt1SoEEntity = "sensor.solaredge_b1_state_of_energy"
    static let batt2SoEEntity = "sensor.solaredge_i3_b1_state_of_energy"

    static var allEntities: [String] {
        [invWestEntity, invEastEntity, batt1SoEEntity, batt2SoEEntity]
    }

    static let refreshInterval: TimeInterval = 5 * 60
    static let historyHours: Int = 24

    enum SharedKey {
        static let baseURL = "ha.baseURL"
        static let lastSnapshot = "ha.lastSnapshot"
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }
}
