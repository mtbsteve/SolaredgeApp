import SwiftUI
import WatchKit

@main
struct SolaredgeWatchApp: App {
    @StateObject private var store = DataStore.shared
    @StateObject private var session = WatchSessionManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        BackgroundRefresh.scheduleNext()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(session)
                .onAppear {
                    session.activate()
                    Task { await store.refresh() }
                }
        }
        .backgroundTask(.appRefresh("solaredge.refresh")) {
            await DataStore.shared.refresh()
            BackgroundRefresh.scheduleNext()
        }
    }
}
