import SwiftUI
import Charts

struct ChartView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Battery SoE — 24h")
                .font(.caption2).foregroundStyle(.secondary)

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
                    AxisMarks(values: .stride(by: .hour, count: 6)) { value in
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
        }
        .padding(.horizontal, 4)
    }
}
