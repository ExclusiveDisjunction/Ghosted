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
    public let source: StatusReviewer;
    public let given: [NSManagedObjectID : ApplicationStatusSnapshot];
    
    @State var bySection: [(JobApplicationState, [ApplicationStatusSnapshot])] = .init();
    @State var selection: Set<NSManagedObjectID> = .init();
    @Environment(\.dismiss) private var dismiss;
    
    private func submit() {
        
    }
    
    public var body: some View {
        SheetBody("Job Application Status Review") {
            StatusReviewPresenter(
                given: given,
                bySection: $bySection,
                selection: $selection
            )
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
