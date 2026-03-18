//
//  StatusColorsSettingsView.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/17/26.
//

import SwiftUI
import ExDisj


public struct StatusColorsSettingsView : View {
    @AppStorage("showStatusColors") private var showStatusColors: Bool = true;
    
    @ViewBuilder
    private var desc: some View {
        Form {
            Section {
                Toggle("Use Status Colors?", isOn: $showStatusColors)
            } footer: {
                Text("Ghosted shows each job application status with colors, to help you quickly differentiate applications.\nHowever, if you have trouble seeing the colors, or they are bothersome, you can disable them here.")
            }
        }
    }
    
    @ViewBuilder
    private var examples: some View {
        List {
            Section("With Colors") {
                VStack(alignment: .leading) {
                    Text(verbatim: "Example 1")
                    
                    DisplayableVisualizer(value: JobApplicationState.accepted)
                        .foregroundStyle(JobApplicationState.accepted.color)
                        .font(.caption)
                }
                
                VStack(alignment: .leading) {
                    Text(verbatim: "Example 2")
                    
                    DisplayableVisualizer(value: JobApplicationState.rejected)
                        .foregroundStyle(JobApplicationState.rejected.color)
                        .font(.caption)
                }
            }
            
            Section("Without Colors") {
                VStack(alignment: .leading) {
                    Text(verbatim: "Example 1")
                    
                    DisplayableVisualizer(value: JobApplicationState.accepted)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                VStack(alignment: .leading) {
                    Text(verbatim: "Example 2")
                    
                    DisplayableVisualizer(value: JobApplicationState.rejected)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    public var content: some View {
        if #available(iOS 18, macOS 15, *) {
            TabView {
                Tab("Settings", systemImage: "gear") {
                    desc
                }
                
                Tab("Examples", systemImage: "list.bullet.rectangle.portrait") {
                    examples
                }
            }
        }
        else {
            TabView {
                desc
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                
                examples
                    .tabItem {
                        Label("Examples", systemImage: "list.bullet.rectangle.portrait")
                    }
            }
        }
    }
    
    public var body: some View {
        content
            .navigationTitle("Status Color Settings")
            .frame(minHeight: 130)
            .padding()
    }
}

#Preview {
    NavigationStack {
        StatusColorsSettingsView()
    }
}
