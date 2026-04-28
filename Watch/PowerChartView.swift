import SwiftUI
import Charts

struct PowerChartView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Power — 24h (kW)")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button { Task { await store.refresh() } } label: {
                    Image(systemName: "arrow.clockwise").font(.caption2)
                }
                .buttonStyle(.plain)
                .disabled(store.isLoading)
            }

            let h = store.history
            if h.solar.isEmpty && h.consumption.isEmpty && h.grid.isEmpty {
                ContentUnavailableView("No history", systemImage: "chart.xyaxis.line")
            } else {
                Chart {
                    ForEach(h.solar, id: \.t) { p in
                        LineMark(x: .value("t", p.t), y: .value("kW", p.v))
                            .foregroundStyle(by: .value("series", "Solar"))
                    }
                    ForEach(h.consumption, id: \.t) { p in
                        LineMark(x: .value("t", p.t), y: .value("kW", p.v))
                            .foregroundStyle(by: .value("series", "Cons."))
                    }
                    ForEach(h.grid, id: \.t) { p in
                        LineMark(x: .value("t", p.t), y: .value("kW", p.v))
                            .foregroundStyle(by: .value("series", "Grid"))
                    }
                }
                .chartForegroundStyleScale([
                    "Solar": .yellow,
                    "Cons.": .red,
                    "Grid": .cyan
                ])
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartLegend(position: .bottom, spacing: 2)
            }

            if let err = store.lastError {
                Text(err).font(.caption2).foregroundStyle(.red).lineLimit(2)
            }
        }
        .padding(.horizontal, 4)
    }
}
