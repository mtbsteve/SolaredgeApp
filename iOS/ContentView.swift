import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: PhoneSessionManager
    @State private var url: String = AppConfig.sharedDefaults.string(forKey: AppConfig.SharedKey.baseURL) ?? ""
    @State private var token: String = KeychainStore.loadToken() ?? ""
    @State private var status: String?
    @State private var testing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Home Assistant") {
                    TextField("https://xxxxx.ui.nabu.casa", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Long-Lived Access Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Button {
                        Task { await test() }
                    } label: {
                        HStack {
                            Text("Test connection")
                            if testing { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(testing || url.isEmpty || token.isEmpty)

                    Button("Save & send to Watch") { save() }
                        .disabled(url.isEmpty || token.isEmpty)
                }

                if let status {
                    Section { Text(status).font(.footnote) }
                }

                Section("Watch") {
                    Text(session.isPaired ? "Watch paired" : "No paired Watch detected")
                    Text(session.isReachable ? "Reachable" : "Not reachable (will deliver in background)")
                        .foregroundStyle(.secondary)
                }

                Section("Entities") {
                    Text("Inv West AC Power: \(AppConfig.invWestEntity)").font(.caption)
                    Text("Inv East AC Power: \(AppConfig.invEastEntity)").font(.caption)
                    Text("SoE Batt 1: \(AppConfig.batt1SoEEntity)").font(.caption)
                    Text("SoE Batt 2: \(AppConfig.batt2SoEEntity)").font(.caption)
                }
            }
            .navigationTitle("Solaredge Setup")
        }
    }

    private func save() {
        AppConfig.sharedDefaults.set(url, forKey: AppConfig.SharedKey.baseURL)
        do {
            try KeychainStore.saveToken(token)
            session.send(url: url, token: token)
            status = "Saved. Sent config to Watch."
        } catch {
            status = "Keychain error: \(error.localizedDescription)"
        }
    }

    private func test() async {
        testing = true; defer { testing = false }
        AppConfig.sharedDefaults.set(url, forKey: AppConfig.SharedKey.baseURL)
        do { try KeychainStore.saveToken(token) } catch {
            status = "Keychain error: \(error.localizedDescription)"; return
        }
        do {
            let snap = try await HAClient.shared.fetchSnapshot()
            status = "OK — West \(fmt(snap.invWestKW)) kW, East \(fmt(snap.invEastKW)) kW, B1 \(fmt(snap.batt1SoE))%, B2 \(fmt(snap.batt2SoE))%"
        } catch {
            status = "Failed: \(error.localizedDescription)"
        }
    }

    private func fmt(_ v: Double?) -> String {
        guard let v else { return "—" }
        return String(format: "%.2f", v)
    }
}
