# SE Monitor for HA

Native watchOS app + iOS companion for displaying solar-photovoltaic sensor values from
Home Assistant on Apple Watch, with a 24-hour battery State-of-Energy chart and a
watch-face complication. Data is fetched directly from your Home Assistant instance via
Nabu Casa Cloud.

> **Disclaimer.** SE Monitor for HA is an independent third-party app. It is **not
> affiliated with, endorsed by, or sponsored by** SolarEdge Technologies, Inc. or the
> Home Assistant project. "SolarEdge" is a trademark of SolarEdge Technologies, Inc.;
> the name is used here only to describe the third-party Home Assistant integrations
> this app reads sensor values from.

- **iOS companion** is for one-time setup only (paste Home Assistant URL + Long-Lived Access
  Token, send to Watch via WatchConnectivity).
- **Watch app** runs standalone afterwards. With an iPhone-paired (non-cellular) Watch, it
  uses the iPhone's connection (incl. cellular) when off Wi-Fi; with a cellular Watch it
  works fully on its own.

> The Xcode project is still named `SolaredgeApp` (and the targets `SolaredgeApp`,
> `SolaredgeWatch`, `SolaredgeWidgets`) for build-system stability — these are internal
> identifiers and never shown to users. The user-facing display names and all in-app
> strings use **SE Monitor for HA**.

## Sensors displayed

The watch app shows two vertically-paged 24h line charts:

**Battery State of Energy (%)** — up to four configurable slots, only configured slots are rendered.

**Power (kW)** — Solar, Consumption, Grid (one entity each).

The watch-face complication shows the instantaneous solar power on the circular, inline,
corner, and rectangular families. The rectangular family additionally lists the
configured battery slots (e.g. `B1 72%  B2 65%`).

### Configurable HA entities

All sensor entity IDs are configured in the iOS companion app under **Power Entities** and
**Battery SoE Entities**. The three power entities are prepopulated with the
SolarEdge Cloud HA integration defaults; override them if your install names them
differently.

| Role          | Default                                       |
|---------------|-----------------------------------------------|
| Solar power   | `sensor.solaredgecloud_solar_power`           |
| Grid power    | `sensor.solaredgecloud_grid_power`            |
| Consumption   | `sensor.solaredgecloud_power_consumption`     |
| Batt 1–4 SoE  | *(empty — installation-specific)*             |

Battery SoE entities come from a Home Assistant integration that pulls data over the
SolarEdge Modbus interface, and their entity IDs depend on how the installation was named.
Enter one entity ID per battery stack; leave unused slots empty (most installs have one or
two stacks). The app is sized for up to four.

The **Verify entities** button pings `/api/states/<id>` for every non-empty field and shows
a per-row badge: ✓ exists, ✗ missing (HTTP 404), ⚠ network/auth error.

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
3. Under **Power Entities**, accept the prepopulated defaults or override them to match the
   entity IDs in your Home Assistant.
4. Under **Battery SoE Entities**, enter one entity ID per battery stack (1–4). Leave
   unused slots empty.
5. Tap **Verify entities** to confirm each ID exists in HA (per-row ✓/✗ badge).
6. Tap **Save & send to Watch**. The full config (URL, token, entity IDs) is delivered via
   WatchConnectivity (instant if the watch app is open, otherwise queued).
7. Build & run the **SolaredgeWatch** scheme on your Apple Watch.
8. Add the **Solaredge Power** complication to a watch face (long-press face → Edit →
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
  AppConfig.swift       — bundle IDs, entity-ID storage + defaults, app group, refresh interval
  HAModels.swift        — HA REST decoding; SensorSnapshot.batterySoE / HistorySeries.batteries are length-4 slot arrays
  HAClient.swift        — async/await client; fetchSnapshot + fetchHistory + entityExists
  KeychainStore.swift   — token persistence (shared keychain group)
iOS/
  SolaredgeAppApp.swift — App entry (companion)
  ContentView.swift     — setup form (URL + token + entity fields + Verify)
  PhoneSessionManager.swift — WCSession sender (URL + token + entities dict)
Watch/
  SolaredgeWatchApp.swift — App entry (watch)
  RootView.swift        — values + chart tabs
  ChartView.swift       — Swift Charts 24h line chart, dynamic per-slot batteries
  DataStore.swift       — @MainActor ObservableObject; refresh + cache
  WatchSessionManager.swift — WCSession receiver, persists URL + token + entity IDs
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

- The kW heuristic in `HAClient.fetchSnapshot()` and `HAClient.fetchHistory()` assumes raw
  values >100 are watts. If your HA power sensors already report kW (or use a different
  unit), adjust the `kw(_:)` / scale logic in `Shared/HAClient.swift`.
- The app supports up to four battery SoE slots. Installations with more stacks would
  require bumping `AppConfig.batterySlotCount` and adding matching fields in the iOS
  settings form.
- 24-hour history can be a sizeable JSON payload over cellular. The request uses
  `minimal_response` and `no_attributes` to keep it small.
- watchOS background-refresh budgets cap real-world cadence; see "Refresh cadence" above.

## App Store description (template)

A copy-pasteable description for App Store Connect. Tweak as needed; the trademark
disclaimer at the end should stay.

```
SE Monitor for HA puts your home solar system on your wrist.

Connect the app once to your Home Assistant instance via Nabu Casa Cloud, point it at
the power and battery sensors you already have configured (defaults match the popular
SolarEdge Cloud HA integration), and your Apple Watch will show:

• A solar-power complication for any watch face — circular, inline, corner, or
  rectangular.
• A 24-hour battery State-of-Energy chart with up to four battery stacks.
• A 24-hour power chart for solar production, consumption, and grid flow.

All data flows directly between your Apple Watch and your Home Assistant — nothing is
sent to any third-party server. Your Long-Lived Access Token is stored only in the
iOS and watchOS Keychain.

Requirements:
• A working Home Assistant instance reachable via Nabu Casa Cloud.
• Power and battery sensors exposed in Home Assistant (the SolarEdge Cloud HA
  integration is one common source; SolarEdge Modbus integrations work too).
• A Long-Lived Access Token from your Home Assistant profile.

Disclaimer: SE Monitor for HA is an independent third-party app. It is not
affiliated with, endorsed by, or sponsored by SolarEdge Technologies, Inc. or the
Home Assistant project. "SolarEdge" is a trademark of SolarEdge Technologies, Inc.
```
