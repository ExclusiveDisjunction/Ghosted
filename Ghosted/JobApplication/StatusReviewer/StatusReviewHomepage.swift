//
//  StatusReviewSheet.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import SwiftUI
import CoreData
import ExDisj
import os

public struct StatusReviewHomepage : View {
    
    @Environment(\.statusReviewer) private var statusReviewer;
    @Environment(\.calendar) private var calendar;
    @Environment(\.accessibilityReduceMotion) private var reduceMotion;
    @AppStorage("statusReviewPeriod") private var statusReviewPeriod: StatusReviewPeriods = .twoWeeks;
    
    @AppStorage("remindAppStatus") private var remindAppStatus: Bool = true;
    
    private func compute(forDays: Int) {
        Task {
            await statusReviewer?.compute(forDays: forDays, calendar: calendar, animated: !reduceMotion, showOnEmpty: true)
        }
    }
    
    public var body: some View {
        VStack {
            Image(systemName: "ellipsis.message")
                .resizable()
                .scaledToFit()
                .frame(width: 98)
                .padding()
            
            Text("Follow-Up Reminders")
                .font(.title2)
            Text("Keep your applications on track")
                .font(.caption)
                .padding(.bottom)
            
            Text("Ghosted can help you determine if you should reach out \nto an employer, or just update the status.")
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            if (statusReviewer?.isLoading ?? false) || (statusReviewer?.showingSheet ?? false) {
                ProgressView()
            }
            else {
                Button("Check for Follow-Ups") {
                    compute(forDays: statusReviewPeriod.rawValue)
                }.disabled(statusReviewer == nil)
                    .buttonStyle(.borderedProminent)
                
                Menu {
                    Button("One Week from Today") {
                        compute(forDays: 7)
                    }
                    
                    Button("Two Weeks from Today") {
                        compute(forDays: 14)
                    }
                    
                    Button("One Month from Today") {
                        compute(forDays: 31)
                    }
                    
                    Button("Two Months from Today") {
                        compute(forDays: 62)
                    }
                } label: {
                    Text("Check follow-ups for...")
                }.disabled(statusReviewer == nil)
                    .buttonStyle(.bordered)
            }
        }.padding()
            .navigationTitle("Follow-Up Reminders")
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable @Environment(\.dataStack) var dataStack;
    @Previewable @State var reviewer: StatusReviewer? = nil;
    
    NavigationStack {
        StatusReviewHomepage()
            .onAppear {
                reviewer = StatusReviewer(container: dataStack, logger: nil)
            }
            .environment(\.statusReviewer, reviewer)
    }
}
