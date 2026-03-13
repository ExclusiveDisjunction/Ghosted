//
//  GhostedApp.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

@MainActor
@Observable
public class GhostedAppState {
    public nonisolated init() async throws {
        persistenceController = DataStack.shared.currentContainer;
        reviewer = StatusReviewer(container: persistenceController);
    }
    
    let persistenceController: NSPersistentContainer;
    let reviewer: StatusReviewer;
}

struct GhostedApp: App {
    init() {
        
    }
    
    @State var state: GhostedAppState?;

    var body: some Scene {
        WindowGroup {
            if let state = state {
                ContentView()
                    .environment(\.managedObjectContext, state.persistenceController.viewContext)
                    .environment(\.statusReviewer, state.reviewer)
            }
            else {
                VStack {
                    Image("IconSVG")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128)
                        .padding()
                    
                    ProgressView("Loading")
                }
            }
            
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
    static func main() async {
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
