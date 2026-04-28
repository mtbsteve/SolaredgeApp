import Foundation
import WatchConnectivity

final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var hasConfig: Bool = AppConfig.sharedDefaults.string(forKey: AppConfig.SharedKey.baseURL) != nil
        && KeychainStore.loadToken() != nil

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
        DispatchQueue.main.async {
            self.hasConfig = AppConfig.sharedDefaults.string(forKey: AppConfig.SharedKey.baseURL) != nil
                && KeychainStore.loadToken() != nil
            Task { await DataStore.shared.refresh() }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) { apply(applicationContext) }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) { apply(userInfo) }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { apply(message) }
}
