import SwiftUI
import Charts

struct ChartView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SolarEdge Monitor")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack {
                Text("Battery SoE — 24h")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button { Task { await store.refresh() } } label: {
                    Image(systemName: "arrow.clockwise").font(.caption2)
                }
                .buttonStyle(.plain)
                .disabled(store.isLoading)
            }

            if store.history.batt1.isEmpty && store.history.batt2.isEmpty {
                ContentUnavailableView("No history", systemImage: "chart.xyaxis.line")
            } else {
                Chart {
                    ForEach(store.history.batt1, id: \.t) { p in
                        LineMark(x: .value("t", p.t), y: .value("SoE", p.v))
                            .foregroundStyle(by: .value("series", "Batt 1"))
                    }
                    ForEach(store.history.batt2, id: \.t) { p in
                        LineMark(x: .value("t", p.t), y: .value("SoE", p.v))
                            .foregroundStyle(by: .value("series", "Batt 2"))
                    }
                }
                .chartForegroundStyleScale([
                    "Batt 1": .green,
                    "Batt 2": .blue
                ])
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { _ in
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
