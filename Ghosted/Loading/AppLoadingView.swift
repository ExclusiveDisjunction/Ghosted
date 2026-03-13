//
//  AppLoadingView.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/13/26.
//

import SwiftUI
import Foundation

public struct AppLoadingView : View {
    @ObservedObject var state: AppLoadingHandle;
    
    public var body: some View {
        VStack {
            Image("IconSVG")
                .resizable()
                .scaledToFit()
                .frame(width: 128)
                .padding()
            
            ProgressView {
                Text(verbatim: state.phase.rawValue)
            }
        }.padding()
    }
}

#Preview {
    AppLoadingView(state: .init())
}
