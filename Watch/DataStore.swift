import Foundation
import WidgetKit

@MainActor
final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var snapshot: SensorSnapshot = .empty
    @Published var history: HistorySeries = .empty
    @Published var lastError: String?
    @Published var isLoading: Bool = false

    private init() { loadCached() }

    func refresh() async {
        isLoading = true; defer { isLoading = false }
        do {
            async let s = HAClient.shared.fetchSnapshot()
            async let h = HAClient.shared.fetchHistory()
            let (snap, hist) = try await (s, h)
            self.snapshot = snap
            self.history = hist
            self.lastError = nil
            cache(snap, hist)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    private func cache(_ s: SensorSnapshot, _ h: HistorySeries) {
        let d = AppConfig.sharedDefaults
        if let sd = try? JSONEncoder().encode(s) { d.set(sd, forKey: "cache.snapshot") }
        if let hd = try? JSONEncoder().encode(h) { d.set(hd, forKey: "cache.history") }
    }

    private func loadCached() {
        let d = AppConfig.sharedDefaults
        if let sd = d.data(forKey: "cache.snapshot"),
           let s = try? JSONDecoder().decode(SensorSnapshot.self, from: sd) {
            self.snapshot = s
        }
        if let hd = d.data(forKey: "cache.history"),
           let h = try? JSONDecoder().decode(HistorySeries.self, from: hd) {
            self.history = h
        }
    }
}
