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
    var invWestKW: Double?
    var invEastKW: Double?
    var batt1SoE: Double?
    var batt2SoE: Double?
    var fetchedAt: Date

    static let empty = SensorSnapshot(invWestKW: nil, invEastKW: nil, batt1SoE: nil, batt2SoE: nil, fetchedAt: .distantPast)
}

struct HistorySeries: Codable, Equatable {
    struct Point: Codable, Equatable {
        let t: Date
        let v: Double
    }
    var batt1: [Point]
    var batt2: [Point]
    var solar: [Point]
    var consumption: [Point]
    var grid: [Point]

    static let empty = HistorySeries(batt1: [], batt2: [], solar: [], consumption: [], grid: [])
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
