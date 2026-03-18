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

public struct Version : Sendable, Equatable, Hashable, Codable, RawRepresentable, CustomStringConvertible, Comparable {
    public init(major: Int, minor: Int, build: Int) {
        self.major = major
        self.minor = minor
        self.build = build
    }
    public init?(rawValue: [Int]) {
        guard rawValue.count == 3 else {
            return nil;
        }
        
        major = rawValue[0]
        minor = rawValue[1]
        build = rawValue[2]
    }
    
    public let major: Int;
    public let minor: Int;
    public let build: Int;
    
    public var rawValue: [Int] {
        [major, minor, build]
    }
    public var description: String {
        "\(major).\(minor) (\(build))"
    }
    
    public static var current: Version? {
        return Version.current(bundle: .main)
    }
    public static func current(bundle: Bundle) -> Version? {
        guard let majorMinor = bundle.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil;
        }
        
        let asParts = majorMinor.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces)}
        guard asParts.count == 2 else {
            return nil;
        }
        
        guard let major = Int(asParts[0]),
              let minor = Int(asParts[1]) else {
            return nil;
        }
        
        guard let rawBuild = bundle.infoDictionary?["CFBundleVersion"] as? String,
              let build = Int(rawBuild.trimmingCharacters(in: .whitespaces)) else {
            return nil;
        }
        
        return Version(major: major, minor: minor, build: build)
    }
    
    public static func <(lhs: Version, rhs: Version) -> Bool {
        lhs.build < rhs.build
    }
    public static func ==(lhs: Version, rhs: Version) -> Bool {
        lhs.build == rhs.build
    }
}

struct ContentView: View {
    @Environment(\.dataStack) private var dataStack;
    @Environment(\.statusReviewer) private var statusReviewer;
    @Environment(\.logger) private var logger;
    @Environment(\.calendar) private var calendar;
    @Environment(\.accessibilityReduceMotion) private var reduceMotion;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @State private var currentPage: Pages? = .jobs;
    
    @AppStorage("statusReviewPeriod") private var statusReviewPeriod: StatusReviewPeriods = .twoWeeks;
    @AppStorage("remindAppStatus") private var remindAppStatus: Bool = true;
    @AppStorage("lastSeenBuild") private var lastSeenBuild: Int?;
    
    enum Pages: Identifiable, Sendable, Equatable, Hashable, Displayable, CaseIterable {
        case jobs
        case followUps
        case stats
#if os(iOS)
        //case help
        case settings
#endif
        
        var display: LocalizedStringKey {
            switch self {
                case .jobs: "Job Applications"
                case .followUps: "Follow-Ups"
                case .stats: "Statistics"
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
            case .stats: JobStatsViewer()
#if os(iOS)
            //case .help: Text("To Do")
            case .settings: SettingsView()
#endif
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading) {
#if os(iOS)
                if horizontalSizeClass == .compact {
                    HStack {
                        Image("IconSVG")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 45)
                        
                        Text("Ghosted")
                            .font(.title)
                    }.padding(.all, 20)
                }
#endif
                
                List(selection: $currentPage) {
                    Section("Jobs") {
                        ForEach([Pages.jobs, .stats, .followUps]) { page in
                            Text(page.display)
                                .tag(page)
                        }
                    }
                    
#if os(iOS)
                    Section("Other") {
                        ForEach([Pages.settings]) { page in
                            Text(page.display)
                                .tag(page)
                        }
                    }
#endif
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
