//
//  TrendsView.swift
//  CloudStroll
//
//  Created by Amey Sunu on 04/08/2025.
//

import SwiftUI
import Charts

struct TrendsView: View {
    @StateObject private var vm = TrendsViewModel()

    @State private var fromDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var toDate = Date()
    @State private var selectedDate: Date?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    DateRangePicker(fromDate: $fromDate, toDate: $toDate)
                    ChartContainer(
                        points: vm.points,
                        isLoading: vm.isLoading,
                        errorMessage: vm.errorMessage,
                        selectedDate: $selectedDate
                    )
                    .frame(height: 350)
                    ScrubSummaryView(
                        points: vm.points,
                        selectedDate: selectedDate
                    )
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mood Trends")
            .onAppear(perform: fetchData)
            .onChange(of: fromDate) { _ in debouncedFetchData() }
            .onChange(of: toDate) { _ in debouncedFetchData() }
        }
    }

    private func fetchData() {
        Task { await vm.fetchTrends(from: fromDate, to: toDate) }
    }
    
    private func debouncedFetchData() {
        searchTask?.cancel()
        searchTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                await vm.fetchTrends(from: fromDate, to: toDate)
            } catch {}
        }
    }
}

// MARK: - Subviews

private struct DateRangePicker: View {
    @Binding var fromDate: Date
    @Binding var toDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                Text("Select Date Range")
                    .font(.headline)
            }
            DatePicker("From", selection: $fromDate, in: ...toDate, displayedComponents: .date)
            DatePicker("To", selection: $toDate, in: fromDate..., displayedComponents: .date)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }
}

private struct ChartContainer: View {
    let points: [TrendPointData]
    let isLoading: Bool
    let errorMessage: String?
    @Binding var selectedDate: Date?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
            
            if !points.isEmpty {
                TrendsChart(points: points, selectedDate: $selectedDate)
                    .padding()
            }
            
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView("Error Loading Data", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
            } else if points.isEmpty && !isLoading {
                ContentUnavailableView("No Data", systemImage: "chart.bar", description: Text("There is no mood trend data available for this date range."))
            }
        }
        .padding(.horizontal)
    }
}

private struct TrendsChart: View {
    let points: [TrendPointData]
    @Binding var selectedDate: Date?

    var body: some View {
        Chart {
            ForEach(points) { pt in
                LineMark(
                    x: .value("Date", pt.date),
                    y: .value("Count", pt.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(pt.color)
                .symbol(by: .value("Mood", pt.mood))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartOverlay { proxy in
            // same scrub code you already have
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if let date: Date = proxy.value(atX: value.location.x) {
                                selectedDate = date
                            }
                        }
                        .onEnded { _ in selectedDate = nil }
                    )
            }
        }
    }
}


private struct ScrubSummaryView: View {
    let points: [TrendPointData]
    let selectedDate: Date?

    var body: some View {
        let selectedPointsOnDay = points.filter {
            guard let selectedDate else { return false }
            return Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
        
        VStack(spacing: 8) {
            Text(selectedDate?.formatted(date: .complete, time: .omitted) ?? " ")
                .font(.headline)
                .foregroundColor(selectedDate == nil ? .clear : .primary)
            
            HStack(spacing: 20) {
                if selectedPointsOnDay.isEmpty {
                    Text("Touch and drag on the chart to see details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedPointsOnDay) { point in
                        HStack(spacing: 4) {
                            Circle().fill(point.color).frame(width: 8, height: 8)
                            Text(point.mood)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.0f", point.value))
                                .font(.caption.bold())
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minHeight: 80, alignment: .top)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .animation(.easeInOut, value: selectedDate)
    }
}
