//
//  ContentView.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData
import ExDisj
import os

struct ContentView: View {
    @Environment(\.dataStack) private var dataStack;
    @Environment(\.statusReviewer) private var statusReviewer;
    @Environment(\.logger) private var logger;
    @Environment(\.calendar) private var calendar;
    @Environment(\.accessibilityReduceMotion) private var reduceMotion;
    
    @State private var currentPage: Pages? = .jobs;
    
    @AppStorage("statusReviewPeriod") private var statusReviewPeriod: StatusReviewPeriods = .twoWeeks;
    @AppStorage("remindAppStatus") private var remindAppStatus: Bool = true;
    
    enum Pages: Identifiable, Sendable, Equatable, Hashable, Displayable, CaseIterable {
        case jobs
        case followUps
#if os(iOS)
        //case help
        case settings
#endif
        
        var display: LocalizedStringKey {
            switch self {
                case .jobs: "Job Applications"
                case .followUps: "Follow-Ups"
#if os(iOS)
                //case .help: "Help"
                case .settings: "Settings"
#endif
            }
        }
        var id: Self {
            self
        }
    }
    
    @ViewBuilder
    private var currentPageView: some View {
        switch (currentPage ?? .jobs) {
            case .jobs: AllApplications()
            case .followUps: StatusReviewHomepage()
#if os(iOS)
            //case .help: Text("To Do")
            case .settings: SettingsView()
#endif
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $currentPage) {
                ForEach(Pages.allCases) { page in
                    Text(page.display)
                        .tag(page)
                }
            }
        } detail: {
            currentPageView
                .focusedSceneValue(\.statusReviewer, statusReviewer)
        }.navigationSplitViewColumnWidth(120)
            .navigationSplitViewStyle(.prominentDetail)
            .navigationTitle(currentPage?.display ?? "Ghosted")
            .withStatusReviewer(statusReviewer)
            .task {
                guard remindAppStatus else {
                    return;
                }
                
                try? await Task.sleep(for: .seconds(0.4))
                await statusReviewer?.compute(forDays: statusReviewPeriod.rawValue, calendar: calendar, animated: !reduceMotion, showOnEmpty: false)
            }
    }

}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    ContentView()
}
