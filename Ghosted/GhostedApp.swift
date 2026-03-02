//
//  GhostedApp.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

@main
struct GhostedApp: App {
    let persistenceController = DataStack.shared.currentContainer;

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }.commands {
            GeneralCommands()
        }
    }
}
