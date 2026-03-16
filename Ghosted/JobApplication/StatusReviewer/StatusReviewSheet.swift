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

public struct StatusReviewSheet : View {
    public init(vm: StatusReviewViewModel) {
        self.vm = vm;
    }
    
    @Bindable var vm: StatusReviewViewModel;
    
    @State var bySection: [(JobApplicationState, [ApplicationStatusSnapshot])] = .init();
    @State var selection: Set<NSManagedObjectID> = .init();
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.statusReviewer) private var statusReviewer;
    @Environment(\.calendar) private var calendar;
    @Environment(\.accessibilityReduceMotion) private var reduceMotion;
    @AppStorage("statusReviewPeriod") private var statusReviewPeriod: StatusReviewPeriods = .twoWeeks;
    
    @AppStorage("remindAppStatus") private var remindAppStatus: Bool = true;
    
    private func submit() {
        guard case .withResults(_) = vm.state else {
            dismiss();
            return;
        }
        
        let newData = StatusReviewPresenter.demangle(bySection: bySection);
        dismiss();
        
        Task {
            await vm.update(newData: newData, calendar: calendar, animated: !reduceMotion)
        }
    }
    private func compute(forDays: Int) {
        Task {
            await vm.compute(forDays: forDays, calendar: calendar, withLoadingSheet: true, animated: !reduceMotion)
        }
    }
    
    @ViewBuilder
    private var idle: some View {
        Image(systemName: "moon")
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
        
        Button("Check for Follow-Ups") {
            compute(forDays: statusReviewPeriod.rawValue)
        }
        
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
        }
    }
    
    @ViewBuilder
    fileprivate static var loading: some View {
        Spacer()
        ProgressView("Loading")
    }
    
    @ViewBuilder
    fileprivate static var error: some View {
        Image(systemName: "exclamationmark.triangle")
            .resizable()
            .scaledToFit()
            .frame(width: 98)
            .padding()
        
        Text("Uh Oh!")
            .font(.title2)
            .padding(.bottom)
        
        Text("We were unable to determine the job applications to review.")
    }
    
    @ViewBuilder
    private func loaded(_ data: StatusReviewPresenter.ById) -> some View {
        StatusReviewPresenter(
            given: data,
            bySection: $bySection,
            selection: $selection
        )
    }
    
    public var body: some View {
        let isEditing = if case .withResults(_) = vm.state { true } else { false }
        
        SheetBody("Job Application Status Review") {
            switch vm.state {
                case .idle: self.idle
                case .loading: Self.loading
                case .hadError: Self.error
                case .withResults(let data): loaded(data)
            }
        } actions: {
            if isEditing {
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
            else {
                OkButton()
            }
        }
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    /*
     @Previewable @State var vm: StatusReviewViewModel? = nil;
     @Previewable @Environment(\.dataStack) var dataStack: DataStack;
     
     if let vm = vm {
     StatusReviewSheet(vm: vm)
     }
     else {
     GeometryReader { _ in
     ProgressView()
     .onAppear {
     let reviewer = StatusReviewer(container: dataStack);
     vm = StatusReviewViewModel(using: reviewer, log: Logger())
     }
     }
     
     }
     */
    
    SheetBody("Job Application Status Review") {
        StatusReviewSheet.error
    }
}
