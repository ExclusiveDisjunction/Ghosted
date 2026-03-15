//
//  AppLoadingErrorView.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/13/26.
//

import SwiftUI
import ExDisj

public struct AppLoadingErrorView : View {
    public init(err: AppLoadError) {
        self.err = err;
    }
    
    private let err: AppLoadError;
    @State private var showingDetails: Bool = false;
    @Environment(\.accessibilityReduceMotion) private var reduceMotion;
    
    public var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 98)
                .padding()
            
            Text("Uh Oh!")
                .font(.title2)
            
            Text("Ghosted could not be loaded. If this issue persists, please contact us.")
            
            Button {
                optionalWithAnimation(isOn: !reduceMotion) {
                    showingDetails.toggle()
                }
            } label: {
                Label(
                    showingDetails ? "Hide Details" : "Show Details",
                    systemImage: showingDetails ? "chevron.up" : "chevron.down"
                )
            }
            
            if showingDetails {
                VStack(alignment: .leading) {
                    Text(verbatim: "During Phase: \(err.phase.rawValue)")
                    Text(verbatim: "Message: \(err.inner.localizedDescription)")
                }
            }
        }.padding()
    }
}

#Preview {
    AppLoadingErrorView(err: .init(phase: .loadingData, inner: CocoaError(.fileNoSuchFile)))
}
