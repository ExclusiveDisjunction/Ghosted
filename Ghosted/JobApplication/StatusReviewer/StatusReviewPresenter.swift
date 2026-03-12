//
//  StatusReviewPresenter.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import SwiftUI
import CoreData
import ExDisj

public struct StatusReviewPresenter : View {
    public let given: [NSManagedObjectID : ApplicationStatusSnapshot];
    
    public typealias BySection = [(JobApplicationState, [ApplicationStatusSnapshot])];
    public typealias ById = [NSManagedObjectID : ApplicationStatusSnapshot];
    
    @Binding var bySection: [(JobApplicationState, [ApplicationStatusSnapshot])];
    @Binding var selection: Set<NSManagedObjectID>;
    
    @Environment(\.managedObjectContext) private var cx;
    
    private func move(ids: Set<NSManagedObjectID>, to: JobApplicationState) {
        var toAdd: [ApplicationStatusSnapshot] = [];
        
        var bySection = self.bySection; //Keeps UI stable until the computation is complete.
        
        for (currentState, applications) in bySection {
            var targetIndices = IndexSet();
            var targets = [ApplicationStatusSnapshot]();
            for (i, app) in applications.enumerated() {
                if ids.contains(app.id) {
                    targetIndices.insert(i)
                    targets.append(app);
                }
            }
            
            toAdd.append(contentsOf: targets);
            // Since our applications is not going to update our true state, we have to manage it here.
            bySection[Int(currentState.rawValue)].1.remove(atOffsets: targetIndices);
        }
        
        bySection[Int(to.rawValue)].1.append(contentsOf: toAdd);
        for state in toAdd {
            state.updateStateTo = to;
        }
        
        withAnimation {
            self.bySection = bySection;
        }
    }
    private func toggleUpdated(ids: Set<NSManagedObjectID>) {
        withAnimation {
            for (_, applications) in bySection {
                for app in applications {
                    if ids.contains(app.id) {
                        app.updatedFlag.toggle()
                    }
                }
            }
        }
    }
    private func openInspector(selection: Set<NSManagedObjectID>) {
        guard !selection.isEmpty else {
            warning.warning = .noneSelected
            return;
        }
        guard selection.count == 1 else {
            warning.warning =  .tooMany;
            return;
        }
        
        inspecting = cx.object(with: selection.first!) as? JobApplication;
    }
    
    /// Turns the `[NSManagedObjectID : ApplicationStatusSnapshot]` into `[(JobApplicationState), [ApplicationStatusSnapshot])]`.
    public nonisolated static func prepare(from: ById) -> BySection {
        var result: [(JobApplicationState, [ApplicationStatusSnapshot])] = JobApplicationState.allCases
            .sorted(using: KeyPathComparator(\.rawValue))
            .map { ($0, []) }
        
        for (_, snapshot) in from {
            let index = Int(snapshot.currentState.rawValue);
            
            result[index].1.append(snapshot)
        }
        
        return result;
    }
    /// Turns the `[(JobApplicationState), [ApplicationStatusSnapshot])]` into `[NSManagedObjectID : ApplicationStatusSnapshot]`.
    public nonisolated static func demangle(bySection: BySection) -> ById {
        var result = [NSManagedObjectID : ApplicationStatusSnapshot]();
        
        for (_, snapshots) in bySection {
            for app in snapshots {
                result[app.id] = app
            }
        }
        
        return result;
    }
    
    @State private var inspecting: JobApplication?;
    @State private var warning: SelectionWarningManifest = .init();
    
    public var body: some View {
        List(selection: $selection) {
            ForEach(bySection, id: \.0) { (state, entries) in
                Section(state.display) {
                    ForEach(entries) { app in
                        VStack(alignment: .leading) {
                            HStack {
                                if !app.didUpdate {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 7, height: 7)
                                }
                                
                                Text(verbatim: "\(app.position) at \(app.company)")
                            }
                            
                            if app.currentState != app.updateStateTo {
                                HStack {
                                    Text(app.currentState.display)
                                    Image(systemName: "arrow.right")
                                    Text(app.updateStateTo.display)
                                }
                            }
                            else {
                                Text(verbatim: "Last Updated \(app.lastUpdated.formatted(date: .numeric, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }.contextMenu(forSelectionType: NSManagedObjectID.self) { selection in
            Section("Mark as") {
                Button("Updated/To Review") {
                    toggleUpdated(ids: selection)
                }
                
                ForEach(JobApplicationState.allCases, id: \.id) { state in
                    Button {
                        move(ids: selection, to: state)
                    } label: {
                        Text(state.display)
                    }
                }
            }
        }.onAppear {
            let results = Self.prepare(from: given)
            withAnimation {
                bySection = results;
            }
        }.withWarning(warning)
            .sheet(item: $inspecting) { target in
                ElementInspector(data: target)
            }
    }
}

#Preview {
    @Previewable @State var given: [NSManagedObjectID : ApplicationStatusSnapshot] = Dictionary(
        uniqueKeysWithValues: [
        JobApplicationState.applied,
        JobApplicationState.applied,
        JobApplicationState.underReview,
        JobApplicationState.inInterview
    ].enumerated().map { (i, state) in
        let id = NSManagedObjectID();
        let targetDate = Calendar.current.date(byAdding: .day, value: -15, to: .now)!
        
        let state = ApplicationStatusSnapshot(
            from: .init(
                id: id,
                position: "Position \(i + 1)",
                company: "Company \(i + 1)",
                current: state,
                lastUpdate: targetDate
            )
        )
        
        return (id, state)
    } )
    @Previewable @State var bySection: [(JobApplicationState, [ApplicationStatusSnapshot])] = .init();
    @Previewable @State var selection: Set<NSManagedObjectID> = .init();
    
    
    StatusReviewPresenter(
        given: given,
        bySection: $bySection,
        selection: $selection
    ).padding()
}
