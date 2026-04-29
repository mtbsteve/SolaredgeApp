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
        if let url = payload["baseURL"] as? String {
            AppConfig.sharedDefaults.set(url, forKey: AppConfig.SharedKey.baseURL)
        }
        if let token = payload["token"] as? String, !token.isEmpty {
            try? KeychainStore.saveToken(token)
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
