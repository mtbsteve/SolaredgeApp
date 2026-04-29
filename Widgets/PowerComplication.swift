import WidgetKit
import SwiftUI

struct SolarEntry: TimelineEntry {
    let date: Date
    let snapshot: SensorSnapshot
}

struct SolarProvider: TimelineProvider {
    func placeholder(in context: Context) -> SolarEntry {
        SolarEntry(date: Date(), snapshot: SensorSnapshot(
            invWestKW: 1.23, invEastKW: 0.98, batt1SoE: 72, batt2SoE: 65, fetchedAt: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (SolarEntry) -> Void) {
        completion(SolarEntry(date: Date(), snapshot: loadCached() ?? placeholder(in: context).snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SolarEntry>) -> Void) {
        let snap = loadCached() ?? placeholder(in: context).snapshot
        let entry = SolarEntry(date: Date(), snapshot: snap)
        let next = Date().addingTimeInterval(AppConfig.refreshInterval)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadCached() -> SensorSnapshot? {
        let d = AppConfig.sharedDefaults
        print("Widget read diag.probe = \(d.string(forKey: "diag.probe") ?? "NIL")")
        let stamp = ISO8601DateFormatter().string(from: Date())
        d.set(stamp, forKey: "diag.widgetRanAt")
        guard let data = d.data(forKey: "cache.snapshot") else { return nil }
        return try? JSONDecoder().decode(SensorSnapshot.self, from: data)
    }
}

struct PowerComplication: Widget {
    let kind = "SolaredgePowerComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SolarProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("Solaredge Power")
        .description("Inverter AC power on the watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: SolarEntry

    private static let maxKW: Double = 10

    private var totalKW: Double {
        (entry.snapshot.invWestKW ?? 0) + (entry.snapshot.invEastKW ?? 0)
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("Solar \(fmtKW(totalKW))")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Gauge(value: min(max(totalKW, 0), Self.maxKW), in: 0...Self.maxKW) {
                    EmptyView()
                } currentValueLabel: {
                    Text(fmtNumber(totalKW))
                        .font(.system(.body, design: .rounded).weight(.semibold).monospacedDigit())
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(Int(Self.maxKW))")
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.orange, .yellow]))
            }
            .widgetLabel("kW")

        case .accessoryCorner:
            // Corner content = small icon at the bezel; widgetLabel = curved text.
            Image(systemName: "sun.max.fill")
                .foregroundStyle(.yellow)
                .widgetLabel {
                    Text("Solar \(fmtKW(totalKW))")
                        .monospacedDigit()
                }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill").foregroundStyle(.yellow)
                    Text("SolarEdge").font(.caption2.weight(.semibold))
                }
                Text("W \(fmtKW(entry.snapshot.invWestKW))   E \(fmtKW(entry.snapshot.invEastKW))")
                    .font(.system(.caption2, design: .rounded).monospacedDigit())
                Text("B1 \(fmtPct(entry.snapshot.batt1SoE))  B2 \(fmtPct(entry.snapshot.batt2SoE))")
                    .font(.system(.caption2, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

        default:
            Text(fmtKW(totalKW))
        }
    }

    private func fmtKW(_ v: Double?) -> String {
        guard let v else { return "—" }
        return String(format: "%.2f kW", v)
    }
    private func fmtNumber(_ v: Double?) -> String {
        guard let v else { return "—" }
        return String(format: "%.1f", v)
    }
    private func fmtPct(_ v: Double?) -> String {
        guard let v else { return "—" }
        return String(format: "%.0f%%", v)
    }
}
