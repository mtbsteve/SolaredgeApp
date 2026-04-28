import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var session: WatchSessionManager

    var body: some View {
        if session.hasConfig {
            TabView {
                ValuesView()
                ChartView()
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

struct ValuesView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                row(label: "Inv West AC Power", value: kw(store.snapshot.invWestKW))
                row(label: "Inv East AC Power", value: kw(store.snapshot.invEastKW))
                Divider()
                row(label: "SoE Batt 1", value: pct(store.snapshot.batt1SoE))
                row(label: "SoE Batt 2", value: pct(store.snapshot.batt2SoE))

                if let err = store.lastError {
                    Text(err).font(.caption2).foregroundStyle(.red)
                }
                HStack {
                    Text(updatedString)
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isLoading)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Solaredge")
    }

    private var updatedString: String {
        guard store.snapshot.fetchedAt > .distantPast else { return "—" }
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short
        return "Updated \(f.string(from: store.snapshot.fetchedAt))"
    }

    private func kw(_ v: Double?) -> String {
        guard let v else { return "—" }
        return String(format: "%.2f kW", v)
    }
    private func pct(_ v: Double?) -> String {
        guard let v else { return "—" }
        return String(format: "%.0f %%", v)
    }
    private func row(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.system(.title3, design: .rounded).monospacedDigit())
        }
    }
}
