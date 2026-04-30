import Foundation
import WatchConnectivity

final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var hasConfig: Bool = AppConfig.sharedDefaults.string(forKey: AppConfig.SharedKey.baseURL) != nil
        && KeychainStore.loadToken() != nil
    @Published var activationState: String = "not activated"
    @Published var lastReceivedAt: String = "never"

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func apply(_ payload: [String: Any]) {
        let d = AppConfig.sharedDefaults
        if let url = payload["baseURL"] as? String {
            d.set(url, forKey: AppConfig.SharedKey.baseURL)
        }
        if let token = payload["token"] as? String, !token.isEmpty {
            try? KeychainStore.saveToken(token)
        }
        // Nested dicts come back through WCSession typed as [String: Any]; coerce per-value.
        if let entities = payload["entities"] as? [String: Any] {
            for (k, raw) in entities {
                let v = (raw as? String) ?? (raw as? NSString as String?) ?? ""
                if v.isEmpty { d.removeObject(forKey: k) } else { d.set(v, forKey: k) }
            }
        }
        let stamp = ISO8601DateFormatter().string(from: Date())
        DispatchQueue.main.async {
            self.lastReceivedAt = stamp
            self.hasConfig = AppConfig.sharedDefaults.string(forKey: AppConfig.SharedKey.baseURL) != nil
                && KeychainStore.loadToken() != nil
            Task { await DataStore.shared.refresh() }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let label: String
        switch activationState {
        case .notActivated: label = "not activated"
        case .inactive: label = "inactive"
        case .activated: label = error == nil ? "activated" : "activated (err: \(error!.localizedDescription))"
        @unknown default: label = "unknown"
        }
        DispatchQueue.main.async { self.activationState = label }
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) { apply(applicationContext) }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) { apply(userInfo) }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { apply(message) }
}
