//
//  GeneralCommands.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import ExDisj

public enum StatusReviewPeriods : Int, Identifiable, Hashable, Equatable, Sendable {
    case week = 7
    case twoWeeks = 14
    case month = 31
    case twoMonths = 62
    
    public var id: Self { self }
}

public struct GeneralCommands : Commands {
    
    @AppStorage("showStatusColors") private var showStatusColors: Bool = true;
    @AppStorage("remindAppStatus") private var remindAppStatus: Bool = true;
    @AppStorage("statusReviewPeriod") private var statusReviewPeriod: StatusReviewPeriods = .twoWeeks;
    
    @FocusedValue(\.jobApplicationManifests) private var jobAppManifests;
    @FocusedValue(\.statusReviewer) private var statusReview;
    
    @Environment(\.openWindow) private var openWindow;
    @Environment(\.calendar) private var calendar;
    @Environment(\.accessibilityReduceMotion) private var reduceMotion;
    
    private func performFollowUps(forDays: Int) {
        Task {
            await statusReview?.compute(forDays: forDays, calendar: calendar, animated: !reduceMotion, showOnEmpty: true);
        }
    }
    
    public var body: some Commands {
        /*
        CommandGroup(after: .undoRedo) {
            Button {
                
            } label: {
                Label("Edit Selected", systemImage: "pencil")
            }.keyboardShortcut("E", modifiers: .command)
            
            Button {
                
            } label: {
                Label("Inspect Selected", systemImage: "info.circle")
            }.keyboardShortcut("I", modifiers: .command)
            
            Button {
                
            } label: {
                Label("Delete Selected", systemImage: "trash")
                    .foregroundStyle(.red)
            }.keyboardShortcut(.delete, modifiers: .command)
                .foregroundStyle(.red)
        }
         */
        
        /*
        CommandMenu("Jobs") {
            Button {
                jobAppManifests?.inspect.openAdding()
            } label: {
                Label("New Application", systemImage: "plus")
            }.keyboardShortcut("N", modifiers: [.command, .shift])
                .disabled(jobAppManifests == nil)
            
            Divider()
            
            Section("Reminders") {
                Toggle(isOn: $remindAppStatus) {
                    Text("Enable Follow-Up Reminders")
                }
                
                Button {
                    performFollowUps(forDays: statusReviewPeriod.rawValue)
                } label: {
                    Text("Check Follow-Ups Now")
                }.keyboardShortcut("F", modifiers: [.command])
                    .disabled(jobAppManifests == nil)
                
                Picker("Default Follow-Up Period", selection: $statusReviewPeriod) {
                    Text("After One Week")
                        .tag(StatusReviewPeriods.week)
                    
                    Text("After Two Weeks")
                        .tag(StatusReviewPeriods.twoWeeks)
                    
                    Text("After One Month")
                        .tag(StatusReviewPeriods.month)
                    
                    Text("After Two Months")
                        .tag(StatusReviewPeriods.twoMonths)
                }.disabled(jobAppManifests == nil)
                
                Menu {
                    Button("One Week from Today") {
                        performFollowUps(forDays: 7)
                    }.keyboardShortcut("1", modifiers: [.command, .option, .shift])
                    
                    Button("Two Weeks from Today") {
                        performFollowUps(forDays: 14)
                    }.keyboardShortcut("2", modifiers: [.command, .option, .shift])
                    
                    Button("One Month from Today") {
                        performFollowUps(forDays: 31)
                    }.keyboardShortcut("4", modifiers: [.command, .option, .shift])
                    
                    Button("Two Months from Today") {
                        performFollowUps(forDays: 62)
                    }.keyboardShortcut("8", modifiers: [.command, .option, .shift])
                } label: {
                    Text("Check Follow-Ups For...")
                }.disabled(jobAppManifests == nil)
            }
        }
         */
        
        CommandGroup(after: .textFormatting) {
            Toggle(isOn: $showStatusColors) {
                Label("Show Colors on Job Status", systemImage: "eyedropper.full")
            }
        }
    }
}
