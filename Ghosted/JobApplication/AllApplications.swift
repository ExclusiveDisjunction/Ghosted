//
//  AllApplications.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

public struct AllApplications : View {
    
    @QuerySelection<JobApplication>(sortDescriptors: [SortDescriptor(\JobApplication.internalAppliedOn)])
    private var applications;
    
    private let warning = SelectionWarningManifest();
    private let inspect = InspectionManifest<JobApplication>();
    private let delete = DeletingManifest<JobApplication>();
    
    @AppStorage("showStatusColors") private var showStatusColors: Bool = true;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @State private var showingFilter = false;
    @State private var showingStats = false;
    
    private var filterState = ApplicationsFilterState();
    @StateObject private var searchState = ApplicationsSearchState();
    
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
    
    public var body: some View {
        Table(context: applications) {
            TableColumn("Position") { app in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(verbatim: app.position)
                        Spacer()
                        DisplayableVisualizer(value: app.state)
                            .foregroundStyle(
                                showStatusColors ? app.state.color : Color.primary
                            )
                    }.swipeActions(edge: .trailing) {
                        SingularContextMenu(app, inspect: inspect, remove: delete, asSlide: true)
                    }
                }
                else {
                    Text(verbatim: app.position)
                }
            }
                .width(min: 100, ideal: 150)
            TableColumn("Company", value: \.company)
            TableColumn("Applied On") { app in
                Text(app.appliedOn.formatted(date: .numeric, time: .omitted))
            }
            TableColumn("Status") { app in
                DisplayableVisualizer(value: app.state)
                    .foregroundStyle(
                        showStatusColors ? app.state.color : Color.primary
                    )
            }
            TableColumn("Location", value: \.location)
            TableColumn("Location Kind", value: \.locationKind)
            TableColumn("Position Kind", value: \.kind)
        }.padding()
            .contextMenu(forSelectionType: JobApplication.ID.self) { selection in
                SelectionContextMenu(
                    context: FrozenSelectionContext(data: applications.data, selection: selection),
                    inspect: inspect,
                    delete: delete,
                    warning: warning
                )
            }
            .withWarning(warning)
            .withElementDeleting(manifest: delete)
            .withElementIE(manifest: inspect) { app in
                app.position = "";
                app.company = "";
                app.appliedOn = .now;
                app.state = .applied;
                app.location = "";
                app.locationKind = .onSite;
                app.kind = .fullTime;
                app.notes = "";
                app.website = nil;
            }
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingStats = true;
                    } label: {
                        Label("Show Statistics", systemImage: "chart.bar")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingFilter = true
                    } label: {
                        Label("Filtering", systemImage: "line.3.horizontal.decrease")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Toggle(isOn: $showStatusColors) {
                        Label("Show Colors on Job Status", systemImage: "eyedropper.full")
                    }
                }
                
                ElementAddButton(inspect: inspect, placement: .primaryAction)
                ElementInspectButton(context: applications, inspect: inspect, warning: warning, placement: .primaryAction)
                ElementEditButton(context: applications, inspect: inspect, warning: warning, placement: .primaryAction)
                ElementDeleteButton(context: applications, delete: delete, warning: warning, placement: .primaryAction)
                
                #if os(iOS)
                ToolbarItem(placement: .automatic) {
                    EditButton()
                }
                #endif
            }
            .navigationTitle("Ghosted")
            .sheet(isPresented: $showingStats) {
                JobStatsViewer()
            }
            .sheet(isPresented: $showingFilter, onDismiss: preparePredicate) {
                JobsFilter(filterState)
            }
            .searchable(text: $searchState.uiQueryString)
            .onChange(of: searchState.queryString ) { _, _ in
                print("Query string updated, changing predicates")
                preparePredicate()
            }
    }
}

#Preview(traits: .sampleData) {
    AllApplications()
}
