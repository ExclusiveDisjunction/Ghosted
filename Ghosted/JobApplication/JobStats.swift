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
    /// Constructs the view around a `NSPersistentContainer`, defaulting to ``DataStack/currentContainer``.
    public init(container: NSPersistentContainer = DataStack.shared.currentContainer) {
        self.container = container;
    }
    
    private let container: NSPersistentContainer;
    @State private var stats: JobStats?;
    @State private var hadError = false;
    
    @Environment(\.dismiss) private var dismiss;
    
    /// Determines the stats on a background context from the container.
    private nonisolated func load() async throws -> JobStats {
        let context = container.newBackgroundContext();
        
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
    
    public var body: some View {
        VStack {
            HStack {
                Text("Job Application Statistics")
                    .font(.title2)
                
                Spacer()
            }
            
            if hadError {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .frame(width: 40, height: 40)
                Text("Unable to determine application statistics!")
            }
            else if let stats = self.stats {
                HStack {
                    Text("Total Applications: \(stats.totalCount)")
                        .font(.headline)
                    Spacer()
                }
                
                ForEach(stats.counts, id: \.0.rawValue) { (state, count) in
                    HStack {
                        DisplayableVisualizer(value: state)
                        Spacer()
                        Text(count, format: .number)
                    }
                }
                
                Divider()
                    .padding(.bottom, 25)
                
                Chart {
                    /*
                     SectorPlot(
                     stats.counts,
                     angle: .value("Count", \.1),
                     angularInset: 2
                     ).foregroundStyle(
                     by: .value("State", \.0)
                     )
                     */
                    ForEach(stats.counts, id: \.0.rawValue) { (state, count) in
                        SectorMark(angle: .value("Count", count), angularInset: 2)
                            .foregroundStyle(by: .value("State", state))
                    }
                }.chartLegend(.visible)
                    .frame(minHeight: 200)
            }
            else {
                ProgressView(label: { Text("Loading Statistics") } )
                    .task {
                        do {
                            let result = try await load();
                            
                            await MainActor.run {
                                withAnimation {
                                    stats = result;
                                }
                            }
                        }
                        catch let e {
                            print("Unable to load stats: \(e)");
                            
                            await MainActor.run {
                                withAnimation {
                                    hadError = true
                                }
                            }
                        }
                    }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    JobStatsViewer()
}
