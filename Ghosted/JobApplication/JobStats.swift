//
//  JobStats.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData
import Charts
import ExDisj

/// Computed set of job applications status.
public struct JobStats : Sendable {
    
    /// For each ``JobApplicationState``, the amount of jobs with that amount.
    ///
    /// By the way this is computed, it will never contain a zero count.
    public let counts: [(JobApplicationState, Int)];
    /// The total count of job applications.
    public let totalCount: Int;
}

extension JobApplicationState : Plottable {
    public var primitivePlottable: Int16 {
        self.rawValue
    }
    public init?(primitivePlottable: PrimitivePlottable) {
        self.init(rawValue: primitivePlottable)
    }
}

/// Computes and visualizes a ``JobStats`` value based on a container.
public struct JobStatsViewer : View {
    /// Constructs the view around a `DataStack`.
    public init() {
        
    }
    
    @State private var stats: JobStats?;
    @State private var hadError = false;
    
    @Environment(\.dataStack) private var dataStack;
    @Environment(\.accessibilityReduceMotion) private var reduceMotion;
    
    /// Determines the stats on a background context from the container.
    private nonisolated func loadRaw() async throws -> JobStats {
        let context = await MainActor.run {
            return dataStack.newBackgroundContext()
        };
        
        let stats = try await context.perform {
            let fetched = try context.fetch(JobApplication.fetchRequest());
            
            var counts: [JobApplicationState: Int] = [:];
            var totalCount = 0;
            for app in fetched {
                counts[app.state, default: 0] += 1;
                totalCount += 1;
            }
            
            return JobStats(counts: Array(counts).sorted(using: KeyPathComparator(\.value)), totalCount: totalCount)
        };
        
        return stats;
    }
    private nonisolated func loadForUI() async {
        do {
            let result = try await loadRaw();
            
            await MainActor.run {
                optionalWithAnimation(isOn: !reduceMotion) {
                    stats = result;
                }
            }
        }
        catch let e {
            print("Unable to load stats: \(e)");
            
            await MainActor.run {
                optionalWithAnimation(isOn: !reduceMotion) {
                    hadError = true
                }
            }
        }
    }
    
    @ViewBuilder
    fileprivate static var withError: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 90)
                .padding()
            
            Text("Uh Oh!")
                .font(.title2)
            Text("Unable to determine application statistics!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }.padding()
    }
    
    @ViewBuilder
    private func totals(stats: JobStats) -> some View {
        List {
            ForEach(stats.counts, id: \.0) { (state, count) in
                HStack {
                    DisplayableVisualizer(value: state)
                    Spacer()
                    Text(count, format: .number)
                }
            }
            
            HStack {
                Text("Total")
                    .bold()
                Spacer()
                Text(stats.totalCount, format: .number)
                    .bold()
            }
        }
    }
    @ViewBuilder
    private func chart(stats: JobStats) -> some View {
        Chart {
            ForEach(stats.counts, id: \.0.rawValue) { (state, count) in
                SectorMark(angle: .value("Count", count), angularInset: 2)
                    .foregroundStyle(by: .value("State", "\(state)"))
            }
        }.chartLegend(.visible)
            .frame(minHeight: 200)
    }
    
    @ViewBuilder
    private var content: some View {
        if hadError {
            Self.withError
        }
        else if let stats = stats {
#if os(macOS)
            HStack {
                VStack(alignment: .leading) {
                    Text("Totals")
                        .font(.title2)
                    
                    totals(stats: stats)
                }.contentShape(Rectangle())
                    .backgroundStyle(.red)
                    .padding()
                
                VStack(alignment: .leading) {
                    Text("Chart")
                        .font(.title2)
                    
                    chart(stats: stats)
                }.contentShape(Rectangle())
                    .backgroundStyle(.blue)
                    .padding()
            }.frame(minWidth: 350, minHeight: 300)
#else
            
            if #available(iOS 18, *) {
                TabView {
                    Tab("Totals", systemImage: "number") {
                        totals(stats: stats)
                    }
                    
                    Tab("Graph", systemImage: "chart.pie") {
                        chart(stats: stats)
                    }
                }
            }
            else {
                TabView {
                    totals(stats: stats)
                        .tabItem {
                            Label("Totals", systemImage: "number")
                        }
                    
                    chart(stats: stats)
                        .tabItem {
                            Label("Chart", systemImage: "chart.pie")
                        }
                }
            }
#endif
        }
        else {
            ProgressView("Loading")
                .task {
                    await loadForUI()
                }
        }
    }
    
    public var body: some View {
        content
            .navigationTitle("Job Statistics")
            .padding()
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .varianceSampleData) {
    NavigationStack {
        JobStatsViewer()
    }
#if os(macOS)
    .frame(width: 400, height: 300)
#endif
}
