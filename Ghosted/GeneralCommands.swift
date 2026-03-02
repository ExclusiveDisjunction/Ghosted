//
//  GeneralCommands.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI

public struct GeneralCommands : Commands {
    
    @AppStorage("showStatusColors") private var showStatusColors: Bool = true;
    
    public var body: some Commands {
        CommandGroup(after: .textFormatting) {
            Toggle(isOn: $showStatusColors) {
                Label("Show Colors on Job Status", systemImage: "eyedropper.full")
            }
        }
    }
}
