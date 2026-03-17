//
//  Settings.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/17/26.
//

import SwiftUI
import ExDisj

enum ThemeMode : Int, Identifiable, CaseIterable, Displayable {
    case light = 0,
         dark = 1,
         system = 2
    
    var display: LocalizedStringKey {
        switch self {
            case .light: "Light"
            case .dark: "Dark"
            case .system: "System"
        }
    }
    
    var id: Self { self }
}

public struct SettingsView : View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system;
    @AppStorage("showStatusColors") private var showStatusColors: Bool = true;
    @AppStorage("remindAppStatus") private var remindAppStatus: Bool = true;
    @AppStorage("statusReviewPeriod") private var statusReviewPeriod: StatusReviewPeriods = .twoWeeks;
    
    @ViewBuilder
    private var statusColors: some View {
        VStack(alignment: .leading) {
            Text("Ghosted shows each job application status with colors, to help you quickly differentiate applications.\nHowever, if you have trouble seeing the colors, or they are bothersome, you can disable them here.")
                .multilineTextAlignment(.leading)
                .frame(minHeight: 80)
            
            Toggle("Use Status Colors?", isOn: $showStatusColors)
            
            Divider()
            
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
        }.navigationTitle("Status Color Settings")
            .frame(minHeight: 130)
            .padding()
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    EnumPicker("Theme", value: $themeMode)
                    NavigationLink("Status Colors") {
                        statusColors
                    }
                }
                
                Section("Follow-Up Reminders") {
                    Toggle("Enable Follow-Up Reminders", isOn: $remindAppStatus)
                    
                    Picker("Follow-Up Period", selection: $statusReviewPeriod) {
                        Text("After One Week")
                            .tag(StatusReviewPeriods.week)
                        
                        Text("After Two Weeks")
                            .tag(StatusReviewPeriods.twoWeeks)
                        
                        Text("After One Month")
                            .tag(StatusReviewPeriods.month)
                        
                        Text("After Two Months")
                            .tag(StatusReviewPeriods.twoMonths)
                    }
                }
            }
        }.padding()
            .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .frame(width: 400, height: 300)
}
