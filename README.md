# SolaredgeApp

Native watchOS app + iOS companion for displaying Home Assistant SolarEdge sensor values
on Apple Watch, with a 24-hour battery State-of-Energy chart and a watch-face complication.
Data is fetched directly from your Home Assistant instance via Nabu Casa Cloud.

- **iOS companion** is for one-time setup only (paste Home Assistant URL + Long-Lived Access
  Token, send to Watch via WatchConnectivity).
- **Watch app** runs standalone afterwards. With an iPhone-paired (non-cellular) Watch, it
  uses the iPhone's connection (incl. cellular) when off Wi-Fi; with a cellular Watch it
  works fully on its own.

## Sensors displayed

| Label              | Entity                                   |
|--------------------|------------------------------------------|
| Inv West AC Power  | `sensor.solaredge_i1_ac_power`           |
| Inv East AC Power  | `sensor.solaredge_i3_ac_power`           |
| SoE Batt 1         | `sensor.solaredge_b1_state_of_energy`    |
| SoE Batt 2         | `sensor.solaredge_i3_b1_state_of_energy` |

The two AC power sensors are shown as instantaneous values formatted `xx.xxkW`.
Both battery State-of-Energy sensors are plotted on a single 24-hour line chart.

## Requirements

- macOS Tahoe + Xcode 16+
- Apple Developer account (paid; free tier cannot install watchOS apps)
- iPhone paired with the target Apple Watch
- Home Assistant reachable via Nabu Casa Cloud (`https://xxxxx.ui.nabu.casa`)
- A Home Assistant **Long-Lived Access Token** (HA → your profile → Security → Long-Lived
  Access Tokens → Create)

## Generating the Xcode project

This repo uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) so the `.xcodeproj` is not
committed.

```bash
brew install xcodegen
cd SolaredgeApp
xcodegen
open SolaredgeApp.xcodeproj
```

## First-time configuration in Xcode

1. Select the project in the Xcode navigator and open the **Signing & Capabilities** tab
   for each target (`SolaredgeApp`, `SolaredgeWatch`, `SolaredgeWidgets`).
2. Set your **Team** (Apple ID).
3. If Xcode complains about the bundle IDs being taken, change the prefix
   `com.mtbsteve.solaredge` to a unique one across all three targets and update the
   `App Group` (`group.<your-prefix>`) and `keychain-access-group` accordingly in:
   - `project.yml`
   - the three `*.entitlements` files
   - `Shared/AppConfig.swift`
   Then re-run `xcodegen`.
4. Confirm the **App Group** and **Keychain Sharing** capabilities are present on all three
   targets and use the same group / access group.

## Running

1. Build & run the **SolaredgeApp** scheme on your iPhone.
2. Enter your Nabu Casa URL (e.g. `https://abcdef1234.ui.nabu.casa`) and your Long-Lived
   Access Token. Tap **Test connection** — you should see live values.
3. Tap **Save & send to Watch**. The config is delivered via WatchConnectivity (instant if
   the watch app is open, otherwise queued).
4. Build & run the **SolaredgeWatch** scheme on your Apple Watch.
5. Add the **Solaredge Power** complication to a watch face (long-press face → Edit →
   Complications).

## Refresh cadence

- The watch app schedules `WKApplication.scheduleBackgroundRefresh` every 5 minutes via
  `BackgroundRefresh.swift` (task identifier `solaredge.refresh`).
- watchOS budgets background refresh aggressively. Apple guarantees roughly **4 refreshes
  per hour** for an active app, but actual cadence depends on watch state (on-wrist, on
  charger, etc.). 5-minute updates are best-effort, not strict.
- Opening the app or tapping the refresh button forces an immediate fetch.
- The complication reloads its timeline whenever the app refreshes
  (`WidgetCenter.shared.reloadAllTimelines()`).

## Architecture

```
Shared/
  AppConfig.swift       — bundle IDs, entity IDs, app group, refresh interval
  HAModels.swift        — HA REST decoding, snapshot & history value types
  HAClient.swift        — async/await client; fetchSnapshot + fetchHistory
  KeychainStore.swift   — token persistence (shared keychain group)
iOS/
  SolaredgeAppApp.swift — App entry (companion)
  ContentView.swift     — setup form (URL + token + test)
  PhoneSessionManager.swift — WCSession sender
Watch/
  SolaredgeWatchApp.swift — App entry (watch)
  RootView.swift        — values + chart tabs
  ChartView.swift       — Swift Charts 24h line chart
  DataStore.swift       — @MainActor ObservableObject; refresh + cache
  WatchSessionManager.swift — WCSession receiver, persists URL+token
  BackgroundRefresh.swift — schedules WKApplication background refresh
Widgets/
  SolaredgeWidgetsBundle.swift — WidgetBundle entry
  PowerComplication.swift — circular / rectangular / inline / corner families
```

The iOS app, Watch app, and widget extension share an **App Group**
(`group.com.mtbsteve.solaredge`) for cached snapshot + history and a **Keychain access
group** for the access token.

## Security notes

- The Long-Lived Access Token grants full HA API access. Treat it like a password.
- The token is stored in the iOS Keychain and synced once to the watch's Keychain via
  WatchConnectivity (encrypted Bluetooth/iCloud channel).
- Never commit the token. `*.token` and `Secrets.xcconfig` are in `.gitignore`.

## Known limitations

- The kW heuristic in `HAClient.fetchSnapshot()` assumes raw values >100 are watts. If your
  HA inverter sensors already report kW (or use a different unit), adjust `kw(_:)` in
  `Shared/HAClient.swift`.
- 24-hour history can be a sizeable JSON payload over cellular. The request uses
  `minimal_response` and `no_attributes` to keep it small.
- watchOS background-refresh budgets cap real-world cadence; see "Refresh cadence" above.
