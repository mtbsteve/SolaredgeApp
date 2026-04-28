import Foundation
import WatchKit

enum BackgroundRefresh {
    static let taskIdentifier = "solaredge.refresh"

    static func scheduleNext() {
        let next = Date().addingTimeInterval(AppConfig.refreshInterval)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: next,
            userInfo: nil
        ) { error in
            if let error { print("scheduleBackgroundRefresh error: \(error)") }
        }
    }
}
