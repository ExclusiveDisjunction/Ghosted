//
//  GhostedApp.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData


struct GhostedApp: App {
    init() {
        persistenceController = DataStack.shared.currentContainer;
        reviewer = StatusReviewer(container: persistenceController);
    }
    
    let persistenceController: NSPersistentContainer;
    let reviewer: StatusReviewer;

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environment(\.statusReviewer, reviewer)
        }.commands {
            GeneralCommands()
        }
    }
}

struct TestingApp : App {
    var body: some Scene {
        WindowGroup {
            Text("Ghosted opened in testing mode")
        }
    }
}

@main
struct EntryPoint {
    static func main() {
        guard isProduction() else {
            TestingApp.main();
            return;
        }
        
        GhostedApp.main();
    }
    
    private static func isProduction() -> Bool {
        return NSClassFromString("XCTestCase") == nil
    }
}
