//
//  GhostedApp.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData
import ExDisj



struct GhostedApp: App {
    init() {
        let state = AppLoadingHandle();
        self._state = .init(wrappedValue: state);
        self.loader = .init(handle: state);
        
        loadingTask = Task { [loader] in
            await loader.load();
        }
    }
    
    let loader: AppLoader;
    @StateObject var state: AppLoadingHandle;
    @State var loadingTask: Task<Void, Never>;

    var body: some Scene {
        WindowGroup {
            AppLoadingView(state: state)
                .environment(\.appLoader, loader)
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
