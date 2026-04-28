import SwiftUI

@main
struct SolaredgeAppApp: App {
    @StateObject private var session = PhoneSessionManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .onAppear { session.activate() }
        }
    }
}
