import WidgetKit
import SwiftUI

struct SolarEntry: TimelineEntry {
    let date: Date
    let snapshot: SensorSnapshot
}

struct SolarProvider: TimelineProvider {
    func placeholder(in context: Context) -> SolarEntry {
        SolarEntry(date: Date(), snapshot: SensorSnapshot(
            batterySoE: [72, 65, nil, nil],
            solarPowerKW: 2.21,
            fetchedAt: Date()
        ))
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
    // New kind forces Carousel to treat this as a brand-new widget,
    // evicting any cached tile from the previous identifier.
    let kind = "SolaredgePower.v2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SolarProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("Solar Power v2")
        .description("Inverter AC power on the watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: SolarEntry

    private static let maxKW: Double = 14

    private var totalKW: Double {
        entry.snapshot.solarPowerKW ?? 0
    }

    /// "B1 72%  B3 65%" — only configured/non-nil slots, in slot order.
    private var batterySummary: String {
        entry.snapshot.batterySoE.enumerated()
            .compactMap { (i, v) -> String? in v.map { String(format: "B%d %.0f%%", i + 1, $0) } }
            .joined(separator: "  ")
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("Solar \(fmtKW(totalKW))")
                .containerBackground(.fill.tertiary, for: .widget)

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Gauge(value: min(max(totalKW, 0), Self.maxKW), in: 0...Self.maxKW) {
                    Text("kW")
                } currentValueLabel: {
                    Text(fmtNumber(totalKW))
                        .font(.system(.body, design: .rounded).weight(.bold).monospacedDigit())
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.red, .orange, .yellow, .green]))
            }
            .containerBackground(.fill.tertiary, for: .widget)

        case .accessoryCorner:
            Image(systemName: "sun.max.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.yellow)
                .widgetLabel("Solar \(fmtKW(totalKW))")
                .containerBackground(.fill.tertiary, for: .widget)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill").foregroundStyle(.yellow)
                    Text("SolarEdge").font(.caption2.weight(.semibold))
                }
                Text("Solar \(fmtKW(entry.snapshot.solarPowerKW))")
                    .font(.system(.body, design: .rounded).weight(.semibold).monospacedDigit())
                if !batterySummary.isEmpty {
                    Text(batterySummary)
                        .font(.system(.caption2, design: .rounded).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)

        default:
            Text(fmtKW(totalKW))
                .containerBackground(.fill.tertiary, for: .widget)
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
}
