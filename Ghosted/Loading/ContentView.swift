//
//  ContentView.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.dataStack) private var dataStack;
    @Environment(\.statusReviewer) private var statusReviewer;
    @State private var statusReviewerVM : StatusReviewViewModel?;

    @ViewBuilder
    private var content: some View {
        NavigationStack {
            AllApplications()
        }
        .focusedValue(\.statusReviewViewModel, statusReviewerVM)
    }
    var body: some View {
        if let vm = statusReviewerVM {
            content.withStatusReviewViewModel(vm)
        }
        else {
            content
        }
    }

}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    ContentView()
}
