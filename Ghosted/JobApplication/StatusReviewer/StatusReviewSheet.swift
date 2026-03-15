//
//  StatusReviewSheet.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import SwiftUI
import CoreData
import ExDisj

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
    
    private func submit() {
        let newData = StatusReviewPresenter.demangle(bySection: bySection);
        dismiss();
        
        Task {
            await vm.update(newData: newData, calendar: calendar, animated: !reduceMotion)
        }
    }
    
    @ViewBuilder
    fileprivate static var idle: some View {
        Image(systemName: "moon")
            .resizable()
            .scaledToFit()
            .frame(width: 98)
            .padding()
        
        Text("")
            .font(.title2)
    }
    
    @ViewBuilder
    fileprivate static var loading: some View {
        
    }
    
    @ViewBuilder
    fileprivate static var error: some View {
        
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
        SheetBody("Job Application Status Review") {
            switch vm.state {
                case .idle: Self.idle
                case .loading: Self.loading
                case .hadError: Self.error
                case .withResults(let data): loaded(data)
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

#Preview {
    VStack {
        StatusReviewSheet.idle
    }.padding()
}
