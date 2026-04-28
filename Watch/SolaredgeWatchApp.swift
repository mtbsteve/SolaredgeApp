import SwiftUI
import WatchKit

@main
struct SolaredgeWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DataStore.shared
    @StateObject private var session = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(session)
                .onAppear {
                    session.activate()
                    Task { await store.refresh() }
                    BackgroundRefresh.scheduleNext()
                }
        }
    }
}
