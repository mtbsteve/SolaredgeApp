import Foundation

enum HAError: Error, LocalizedError {
    case notConfigured
    case badURL
    case http(Int)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Home Assistant URL or token not configured."
        case .badURL: return "Invalid Home Assistant URL."
        case .http(let code): return "HTTP \(code)"
        case .decoding(let e): return "Decode error: \(e.localizedDescription)"
        case .transport(let e): return "Network error: \(e.localizedDescription)"
        }
    }
}

actor HAClient {
    static let shared = HAClient()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private var baseURL: URL? {
        guard let s = AppConfig.sharedDefaults.string(forKey: AppConfig.SharedKey.baseURL),
              let u = URL(string: s) else { return nil }
        return u
    }

    private var token: String? { KeychainStore.loadToken() }

    private func request(path: String, query: [URLQueryItem] = []) throws -> URLRequest {
        guard let base = baseURL, let token = token else { throw HAError.notConfigured }
        var comps = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty { comps?.queryItems = query }
        guard let url = comps?.url else { throw HAError.badURL }
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return req
    }

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let s = try c.decode(String.self)
            if let dt = iso.date(from: s) { return dt }
            if let dt = isoNoFrac.date(from: s) { return dt }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Bad date \(s)")
        }
        return d
    }

    func fetchState(entityId: String) async throws -> HAState {
        let req = try request(path: "/api/states/\(entityId)")
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw HAError.http((resp as? HTTPURLResponse)?.statusCode ?? -1)
            }
            return try decoder().decode(HAState.self, from: data)
        } catch let e as HAError { throw e }
        catch let e as DecodingError { throw HAError.decoding(e) }
        catch { throw HAError.transport(error) }
    }

    /// Returns true if the entity exists and HA returns a state for it.
    func entityExists(entityId: String) async -> Bool {
        do { _ = try await fetchState(entityId: entityId); return true } catch { return false }
    }

    func fetchSnapshot() async throws -> SensorSnapshot {
        async let solar = fetchState(entityId: AppConfig.solarPowerEntity)
        let batterySlots = AppConfig.batteryEntitySlots

        // Fetch each configured battery slot in parallel; nil-slots stay nil.
        let battTask = Task { () -> [Double?] in
            await withTaskGroup(of: (Int, Double?).self) { group in
                for (idx, eid) in batterySlots.enumerated() {
                    guard let eid else { continue }
                    group.addTask {
                        let s = try? await self.fetchState(entityId: eid)
                        return (idx, s?.doubleValue)
                    }
                }
                var result: [Double?] = batterySlots.map { _ in nil }
                for await (idx, v) in group { result[idx] = v }
                return result
            }
        }

        let sp = try await solar
        let batt = await battTask.value

        // HA reports W; spec wants kW
        func kw(_ s: HAState) -> Double? {
            guard let v = s.doubleValue else { return nil }
            // Heuristic: if value > 100, assume W; otherwise assume already kW.
            return abs(v) > 100 ? v / 1000.0 : v
        }
        return SensorSnapshot(
            batterySoE: batt,
            solarPowerKW: kw(sp),
            fetchedAt: Date()
        )
    }

    func fetchHistory(hours: Int = AppConfig.historyHours) async throws -> HistorySeries {
        let start = Date().addingTimeInterval(-Double(hours) * 3600)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let startStr = iso.string(from: start)

        let solarId = AppConfig.solarPowerEntity
        let consumptionId = AppConfig.consumptionEntity
        let gridId = AppConfig.gridPowerEntity
        let batterySlots = AppConfig.batteryEntitySlots
        let configuredBatteryIds = batterySlots.compactMap { $0 }

        let entityIds = [solarId, consumptionId, gridId] + configuredBatteryIds
        let powerEntityIds: Set<String> = [solarId, consumptionId, gridId]

        let req = try request(
            path: "/api/history/period/\(startStr)",
            query: [
                URLQueryItem(name: "filter_entity_id", value: entityIds.joined(separator: ",")),
                URLQueryItem(name: "minimal_response", value: nil),
                URLQueryItem(name: "no_attributes", value: nil)
            ]
        )
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw HAError.http((resp as? HTTPURLResponse)?.statusCode ?? -1)
            }
            let arrays = try decoder().decode([[HAHistoryPoint]].self, from: data)

            var batteries: [[HistorySeries.Point]] = batterySlots.map { _ in [] }
            var solar: [HistorySeries.Point] = []
            var cons: [HistorySeries.Point] = []
            var grid: [HistorySeries.Point] = []

            for series in arrays {
                guard let first = series.first, let eid = first.entity_id else { continue }
                let isPower = powerEntityIds.contains(eid)
                let scale: Double = {
                    guard isPower else { return 1.0 }
                    // Heuristic: assume W if any sample > 100, else already kW
                    let anyLarge = series.contains { ($0.doubleValue.map { abs($0) } ?? 0) > 100 }
                    return anyLarge ? 1.0 / 1000.0 : 1.0
                }()
                let mapped: [HistorySeries.Point] = series.compactMap { p in
                    guard let t = p.last_changed, let v = p.doubleValue else { return nil }
                    return .init(t: t, v: v * scale)
                }
                if eid == solarId { solar = mapped }
                else if eid == consumptionId { cons = mapped }
                else if eid == gridId { grid = mapped }
                else if let slot = batterySlots.firstIndex(where: { $0 == eid }) { batteries[slot] = mapped }
            }
            return HistorySeries(batteries: batteries, solar: solar, consumption: cons, grid: grid)
        } catch let e as HAError { throw e }
        catch let e as DecodingError { throw HAError.decoding(e) }
        catch { throw HAError.transport(error) }
    }
}
