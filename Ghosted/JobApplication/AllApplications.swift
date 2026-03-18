//
//  AllApplications.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData
import ExDisj

/// A view that provides an overview of all job applications, with the ability to filter, search, and provide statistics.
public struct AllApplications : View {
    
    @QuerySelection<JobApplication>(sortDescriptors: [SortDescriptor(\JobApplication.internalAppliedOn)])
    private var applications;
    
    @State private var manifests: JobApplicationsManifests = .init();
    
    @AppStorage("showStatusColors") private var showStatusColors: Bool = true;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.dataStack) private var dataStack;
    
    @State private var showingFilter = false;
    
    private var filterState = ApplicationsFilterState();
    @StateObject private var searchState = ApplicationsSearchState();
    
    /// Fetches the latest predicates from the filtering and searching.
    private func preparePredicate() {
        let filterPred = filterState.preparePredicate();
        
        let pred: NSPredicate;
        if let searchPred = searchState.computePredicate() {
            pred = NSCompoundPredicate(andPredicateWithSubpredicates: [filterPred, searchPred])
        }
        else {
            pred = filterPred
        }
        
        _applications.configure(predicate: pred)
    }
    
    @ViewBuilder
    private func firstCol(app: JobApplication) -> some View {
        if horizontalSizeClass == .compact {
            VStack(alignment: .leading) {
                Text(verbatim: app.position)
                
                DisplayableVisualizer(value: app.state)
                    .foregroundStyle(
                        showStatusColors && !applications.contains(app.id) ? app.state.color : Color.primary
                    )
                    .font(.caption)
            }.swipeActions(edge: .trailing) {
                SingularContextMenu(app, inspect: manifests.inspect, remove: manifests.delete, asSlide: true)
            }
        }
        else {
            Text(verbatim: app.position)
        }
    }
    
    public var body: some View {
        Table(context: applications) {
            TableColumn("Position", content: firstCol)
                .width(min: 100, ideal: 150)
            TableColumn("Company", value: \.company)
            TableColumn("Applied On") { app in
                Text(app.appliedOn.formatted(date: .numeric, time: .omitted))
            }
            TableColumn("Status") { app in
                DisplayableVisualizer(value: app.state)
                    .foregroundStyle(
                        showStatusColors && !applications.contains(app.id) ? app.state.color : Color.primary
                    )
            }
            TableColumn("Location", value: \.location)
            TableColumn("Location Kind", value: \.locationKind)
            TableColumn("Position Kind", value: \.kind)
        }.padding()
            .contextMenu(forSelectionType: JobApplication.ID.self) { selection in
                SelectionContextMenu(
                    context: FrozenSelectionContext(data: applications.data, selection: selection),
                    inspect: manifests.inspect,
                    delete: manifests.delete,
                    warning: manifests.warning
                )
            }
            .withWarning(manifests.warning)
            .withElementDeleting(manifest: manifests.delete)
            .withElementIE(manifest: manifests.inspect, using: dataStack) { app in
                app.position = "";
                app.company = "";
                app.appliedOn = .now;
                app.state = .applied;
                app.lastStatusUpdated = .now;
                app.location = "";
                app.locationKind = .onSite;
                app.kind = .fullTime;
                app.notes = "";
                app.website = nil;
            }
            .toolbar {
                #if os(iOS)
                let placement = ToolbarItemPlacement.topBarTrailing
                #else
                let placement = ToolbarItemPlacement.secondaryAction;
                #endif
                
                ToolbarItem(placement: placement) {
                    Button {
                        showingFilter = true
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease")
                    }
                }
                
                ElementAddButton(inspect: manifests.inspect, placement: .primaryAction)
                ElementInspectButton(context: applications, inspect: manifests.inspect, warning: manifests.warning, placement: .primaryAction)
                ElementEditButton(context: applications, inspect: manifests.inspect, warning: manifests.warning, placement: .primaryAction)
                ElementDeleteButton(context: applications, delete: manifests.delete, warning: manifests.warning, placement: .primaryAction)
                
                #if os(iOS)
                ToolbarItem(placement: .automatic) {
                    EditButton()
                }
                #endif
            }
            .navigationTitle("Ghosted")
            .sheet(isPresented: $showingFilter, onDismiss: preparePredicate) {
                JobsFilter(filterState)
            }
            .searchable(text: $searchState.uiQueryString)
            .onChange(of: searchState.queryString ) { _, _ in
                preparePredicate()
            }
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    NavigationStack {
        AllApplications()
    }
}
