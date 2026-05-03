import Foundation

struct HAState: Decodable {
    let entity_id: String
    let state: String
    let last_updated: Date?
    let attributes: [String: AnyCodable]?

    var doubleValue: Double? { Double(state) }
}

struct HAHistoryPoint: Decodable {
    let entity_id: String?
    let state: String
    let last_changed: Date?

    var doubleValue: Double? { Double(state) }
}

struct SensorSnapshot: Codable, Equatable {
    /// One entry per battery slot (1...AppConfig.batterySlotCount). nil = unconfigured or unreadable.
    var batterySoE: [Double?]
    var solarPowerKW: Double?
    var fetchedAt: Date

    static let empty = SensorSnapshot(
        batterySoE: Array(repeating: nil, count: AppConfig.batterySlotCount),
        solarPowerKW: nil,
        fetchedAt: .distantPast
    )
}

struct HistorySeries: Codable, Equatable {
    struct Point: Codable, Equatable {
        let t: Date
        let v: Double
    }
    /// One series per battery slot (1...AppConfig.batterySlotCount). Empty = unconfigured or no data.
    var batteries: [[Point]]
    var solar: [Point]
    var consumption: [Point]
    var grid: [Point]

    static let empty = HistorySeries(
        batteries: Array(repeating: [], count: AppConfig.batterySlotCount),
        solar: [], consumption: [], grid: []
    )

    /// HA's history endpoint with `minimal_response` only emits state-change events,
    /// so a value that has been constant since the last change has no recent point.
    /// Append a synthetic carry-forward point at `date` with the last known value so
    /// charts extend to the right edge instead of ending mid-axis.
    static func carryingForward(_ series: [Point], to date: Date) -> [Point] {
        guard let last = series.last, date > last.t else { return series }
        return series + [Point(t: date, v: last.v)]
    }
}

struct AnyCodable: Codable {
    let value: Any
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self) { value = v }
        else if let v = try? c.decode(Double.self) { value = v }
        else if let v = try? c.decode(String.self) { value = v }
        else if c.decodeNil() { value = NSNull() }
        else { value = NSNull() }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        default: try c.encodeNil()
        }
    }
}
