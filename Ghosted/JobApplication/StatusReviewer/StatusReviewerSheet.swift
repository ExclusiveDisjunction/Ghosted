//
//  StatusReviewPresenter.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import SwiftUI
import CoreData
import ExDisj

public struct StatusReviewerSheet : View {
    public init(vm: StatusReviewer, given: StatusReviewer.ById) {
        self.vm = vm;
        self.given = given;
    }
    
    public typealias BySection = [(JobApplicationState, [ApplicationStatusSnapshot])];
    
    private let vm: StatusReviewer;
    private let given: StatusReviewer.ById;
    @State var bySection: StatusReviewerSheet.BySection = .init();
    @State var selection: Set<NSManagedObjectID> = .init();
    
    @Environment(\.managedObjectContext) private var cx;
    @Environment(\.calendar) private var calendar;
    @Environment(\.accessibilityReduceMotion) private var reduceMotion;
    @Environment(\.dismiss) private var dismiss;
    
    public static nonisolated func move(ids: Set<NSManagedObjectID>, to: JobApplicationState, starting: BySection) async -> BySection {
        var toAdd: [ApplicationStatusSnapshot] = [];
        var starting = starting;

        for (currentState, applications) in starting {
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
            starting[Int(currentState.rawValue)].1.remove(atOffsets: targetIndices);
        }
        
        starting[Int(to.rawValue)].1.append(contentsOf: toAdd);
        await MainActor.run {
            for state in toAdd {
                state.updateStateTo = to;
            }
        }
        
        return starting;
    }
    
    private func move(ids: Set<NSManagedObjectID>, to: JobApplicationState) {
        Task(priority: .userInitiated) {
            let result = await Self.move(ids: ids, to: to, starting: self.bySection)
            
            await MainActor.run {
                optionalWithAnimation(isOn: !reduceMotion) {
                    self.bySection = result;
                }
            }
        }
    }
    private func toggleUpdated(ids: Set<NSManagedObjectID>) {
        optionalWithAnimation(isOn: !reduceMotion) {
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
    private func submit() {
        let newData = StatusReviewerSheet.demangle(bySection: bySection);
        dismiss();
        
        Task {
            await vm.update(newData: newData, calendar: calendar, animated: !reduceMotion)
        }
    }
    
    public nonisolated static func prepare(from: StatusReviewer.ById) -> BySection {
        var result: [(JobApplicationState, [ApplicationStatusSnapshot])] = JobApplicationState.allCases
            .sorted(using: KeyPathComparator(\.rawValue))
            .map { ($0, []) }
        
        for (_, snapshot) in from {
            let index = Int(snapshot.currentState.rawValue);
            
            result[index].1.append(snapshot)
        }
        
        return result;
    }
    public nonisolated static func demangle(bySection: BySection) -> StatusReviewer.ById {
        var result = StatusReviewer.ById();
        
        for (_, snapshots) in bySection {
            for app in snapshots {
                result[app.id] = app
            }
        }
        
        return result;
    }
    
    @State private var inspecting: JobApplication?;
    @State private var warning: SelectionWarningManifest = .init();
    
    @ViewBuilder
    private func entryDisplay(app: ApplicationStatusSnapshot) -> some View {
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
    
    @ViewBuilder
    private var content: some View {
        List(bySection, id: \.0, selection: $selection) { (state, entries) in
            Section(state.display) {
                ForEach(entries, content: entryDisplay)
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
            optionalWithAnimation(isOn: !reduceMotion) {
                bySection = results;
            }
        }.withWarning(warning)
            .sheet(item: $inspecting) { target in
                ElementInspector(data: target)
            }
            .frame(minHeight: 200, idealHeight: 250)
    }
    
    @ViewBuilder
    private var nothingToDo: some View {
        Image(systemName: "moon")
            .resizable()
            .scaledToFit()
            .frame(width: 90)
            .padding()
        
        Text("You are all caught up!")
            .font(.title2)
        Text("Ghosted found no jobs to update")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    public var body: some View {
        SheetBody("Follow Up Reminders") {
            if given.isEmpty {
                nothingToDo
            }
            else {
                content
            }
        } actions: {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
            }.buttonStyle(.bordered)
            
            Button {
                submit()
            } label: {
                Text("Save")
            }.buttonStyle(.borderedProminent)
        }
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .varianceSampleData) {
    @Previewable @Environment(\.dataStack) var dataStack;
    @Previewable @Environment(\.calendar) var calendar;
    @Previewable @State var reviewer: StatusReviewer?;
    @Previewable @State var sampleData: StatusReviewer.ById?;
    
    NavigationStack {
        if let reviewer = reviewer, let sampleData = sampleData {
            StatusReviewerSheet(vm: reviewer, given: sampleData)
        }
        else {
            ProgressView()
                .task {
                    reviewer = StatusReviewer(container: dataStack, logger: nil)
                    sampleData = try? await reviewer?.compute(daysToCheck: 14, relativeTo: .now, calendar: calendar)
                }
        }
    }.frame(width: 400, height: 350)
}
