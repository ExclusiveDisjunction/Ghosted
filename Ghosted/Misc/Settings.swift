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
    @AppStorage("remindAppStatus") private var remindAppStatus: Bool = true;
    @AppStorage("statusReviewPeriod") private var statusReviewPeriod: StatusReviewPeriods = .twoWeeks;

    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    EnumPicker("Theme", value: $themeMode)
                    NavigationLink("Status Colors") {
                        StatusColorsSettingsView()
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
