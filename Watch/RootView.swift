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
            VStack(spacing: 8) {
                Image(systemName: "iphone.gen3")
                    .font(.title2)
                Text("Open the Solaredge app on iPhone to send config.")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
            }
            .padding()
        }
    }
}
