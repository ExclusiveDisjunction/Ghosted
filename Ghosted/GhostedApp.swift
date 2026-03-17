//
//  GhostedApp.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData
import ExDisj
import os

public extension EnvironmentValues {
    @Entry var logger: Logger? = nil;
}



struct GhostedApp: App {
    init() {
        let state = AppLoadingHandle();
        self._state = .init(wrappedValue: state);
        self.loader = .init(handle: state);
        
        loadingTask = Task { [loader] in
            await loader.load(animated: true);
        }
    }
    
    let loader: AppLoader;
    @StateObject var state: AppLoadingHandle;
    let loadingTask: Task<Void, Never>;
    
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system;
    
    private var colorScheme: ColorScheme? {
        switch themeMode {
            case .light: return .light
            case .dark: return .dark
            default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            LoadingGate(state: state) {
                ContentView()
            }.preferredColorScheme(colorScheme)
        }.commands(content: GeneralCommands.init)
            .environment(\.appLoader, loader)
        
#if os(macOS)
        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
#endif
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
