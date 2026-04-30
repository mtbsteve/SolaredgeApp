import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: PhoneSessionManager
    @State private var url: String = AppConfig.sharedDefaults.string(forKey: AppConfig.SharedKey.baseURL) ?? ""
    @State private var token: String = KeychainStore.loadToken() ?? ""

    @State private var solarEntity: String = AppConfig.solarPowerEntity
    @State private var gridEntity: String = AppConfig.gridPowerEntity
    @State private var consumptionEntity: String = AppConfig.consumptionEntity
    @State private var battEntities: [String] = ContentView.loadBatteries()

    @State private var status: String?
    @State private var testing = false
    @State private var verifying = false
    @State private var verifyResults: [String: VerifyResult] = [:]

    enum VerifyResult: Equatable { case ok, missing, error(String) }

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

                Section {
                    entityRow("Solar power", text: $solarEntity, key: AppConfig.DefaultEntity.solarPower)
                    entityRow("Grid power", text: $gridEntity, key: AppConfig.DefaultEntity.gridPower)
                    entityRow("Consumption", text: $consumptionEntity, key: AppConfig.DefaultEntity.consumption)
                } header: {
                    Text("Power Entities")
                } footer: {
                    Text("Defaults match the SolarEdge Cloud HA integration. Override if your entities are named differently.")
                }

                Section {
                    ForEach(0..<AppConfig.batterySlotCount, id: \.self) { i in
                        entityRow("Batt \(i + 1) SoE", text: $battEntities[i], key: nil)
                    }
                } header: {
                    Text("Battery SoE Entities")
                } footer: {
                    Text("Leave empty if not used. SolarEdge Modbus integration entity ids vary by installation.")
                }

                Section {
                    Button {
                        Task { await verify() }
                    } label: {
                        HStack {
                            Text("Verify entities")
                            if verifying { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(verifying || url.isEmpty || token.isEmpty)
                    Button("Reset entities to defaults", role: .destructive) { resetEntities() }
                }
            }
            .navigationTitle("Solaredge Setup")
        }
    }

    @ViewBuilder
    private func entityRow(_ label: String, text: Binding<String>, key: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                verifyBadge(for: text.wrappedValue)
            }
            TextField(key ?? "sensor.your_entity_id", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
        }
    }

    @ViewBuilder
    private func verifyBadge(for entityId: String) -> some View {
        let trimmed = entityId.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            EmptyView()
        } else if let r = verifyResults[trimmed] {
            switch r {
            case .ok:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .missing:
                Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
        }
    }

    private static func loadBatteries() -> [String] {
        let d = AppConfig.sharedDefaults
        return (1...AppConfig.batterySlotCount).map { d.string(forKey: AppConfig.SharedKey.batteryEntity($0)) ?? "" }
    }

    private func currentEntityPayload() -> [String: String] {
        var out: [String: String] = [
            AppConfig.SharedKey.solarPowerEntity: solarEntity.trimmingCharacters(in: .whitespacesAndNewlines),
            AppConfig.SharedKey.gridPowerEntity: gridEntity.trimmingCharacters(in: .whitespacesAndNewlines),
            AppConfig.SharedKey.consumptionEntity: consumptionEntity.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        for i in 0..<AppConfig.batterySlotCount {
            out[AppConfig.SharedKey.batteryEntity(i + 1)] = battEntities[i].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return out
    }

    private func persistEntities() {
        let d = AppConfig.sharedDefaults
        for (k, v) in currentEntityPayload() {
            if v.isEmpty { d.removeObject(forKey: k) } else { d.set(v, forKey: k) }
        }
    }

    private func resetEntities() {
        solarEntity = AppConfig.DefaultEntity.solarPower
        gridEntity = AppConfig.DefaultEntity.gridPower
        consumptionEntity = AppConfig.DefaultEntity.consumption
        battEntities = Array(repeating: "", count: AppConfig.batterySlotCount)
        verifyResults.removeAll()
    }

    private func save() {
        AppConfig.sharedDefaults.set(url, forKey: AppConfig.SharedKey.baseURL)
        persistEntities()
        do {
            try KeychainStore.saveToken(token)
            session.send(url: url, token: token, entities: currentEntityPayload())
            status = "Saved. Sent config to Watch."
        } catch {
            status = "Keychain error: \(error.localizedDescription)"
        }
    }

    private func test() async {
        testing = true; defer { testing = false }
        AppConfig.sharedDefaults.set(url, forKey: AppConfig.SharedKey.baseURL)
        persistEntities()
        do { try KeychainStore.saveToken(token) } catch {
            status = "Keychain error: \(error.localizedDescription)"; return
        }
        do {
            let snap = try await HAClient.shared.fetchSnapshot()
            let battSummary = snap.batterySoE.enumerated()
                .compactMap { (i, v) -> String? in v.map { String(format: "B%d %.0f%%", i + 1, $0) } }
                .joined(separator: ", ")
            status = "OK — Solar \(fmt(snap.solarPowerKW)) kW" + (battSummary.isEmpty ? "" : ", \(battSummary)")
        } catch {
            status = "Failed: \(error.localizedDescription)"
        }
    }

    private func verify() async {
        verifying = true; defer { verifying = false }
        AppConfig.sharedDefaults.set(url, forKey: AppConfig.SharedKey.baseURL)
        do { try KeychainStore.saveToken(token) } catch {
            status = "Keychain error: \(error.localizedDescription)"; return
        }
        let ids = [solarEntity, gridEntity, consumptionEntity] + battEntities
        let unique = Array(Set(ids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }))
        var newResults: [String: VerifyResult] = [:]
        await withTaskGroup(of: (String, VerifyResult).self) { group in
            for id in unique {
                group.addTask {
                    do {
                        _ = try await HAClient.shared.fetchState(entityId: id)
                        return (id, .ok)
                    } catch HAError.http(404) {
                        return (id, .missing)
                    } catch {
                        return (id, .error(error.localizedDescription))
                    }
                }
            }
            for await (id, r) in group { newResults[id] = r }
        }
        verifyResults = newResults
        let okCount = newResults.values.filter { $0 == .ok }.count
        status = "Verified \(okCount)/\(newResults.count) entities."
    }

    private func fmt(_ v: Double?) -> String {
        guard let v else { return "—" }
        return String(format: "%.2f", v)
    }
}
