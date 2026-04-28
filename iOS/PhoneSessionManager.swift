import Foundation
import WatchConnectivity

final class PhoneSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()

    @Published var isPaired: Bool = false
    @Published var isReachable: Bool = false

    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    func activate() {
        guard let s = session else { return }
        s.delegate = self
        s.activate()
    }

    func send(url: String, token: String) {
        guard let s = session, s.activationState == .activated else { return }
        let payload: [String: Any] = ["baseURL": url, "token": token]
        do {
            try s.updateApplicationContext(payload)
        } catch {
            // fall through to transferUserInfo
        }
        s.transferUserInfo(payload)
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil) { _ in }
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
            self.isReachable = session.isReachable
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }
}
