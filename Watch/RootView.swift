import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var session: WatchSessionManager

    var body: some View {
        if session.hasConfig {
            TabView {
                ChartView()
                PowerChartView()
            }
            .tabViewStyle(.verticalPage)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "iphone.gen3").font(.title2)
                    Text("Open the Solaredge app on iPhone to send config.")
                        .multilineTextAlignment(.leading)
                        .font(.footnote)
                    Divider()
                    Group {
                        Text("WCSession: \(session.activationState)")
                        Text("Last received: \(session.lastReceivedAt)")
                        Text("URL set: \(AppConfig.sharedDefaults.string(forKey: AppConfig.SharedKey.baseURL) != nil ? "yes" : "no")")
                        Text("Token in keychain: \(KeychainStore.loadToken() != nil ? "yes" : "no")")
                    }
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
            }
        }
    }
}
