//
//  AppLoader.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/13/26.
//

import SwiftUI
import CoreData
import os
import ExDisj
import Combine

public enum AppLoadingPhase : String, Sendable {
    case loadingData = "Loading Data"
    case reviewingApps = "Reviewing Job Applications"
    case wrappingUp = "Wrapping Up"
}
public struct AppLoadError : Error {
    public let phase: AppLoadingPhase;
    public let inner: any Error;
}



public struct LoadedAppState : Sendable {
    let stack: DataStack;
    let reviewer: StatusReviewer;
}
public extension View {
    func withLoadedApp(_ state: LoadedAppState) -> some View {
        self
            .environment(\.dataStack, state.stack)
            .environment(\.statusReviewer, state.reviewer)
    }
}

public enum AppLoadingStates : Sendable, Identifiable{
    case loading
    case err(AppLoadError)
    case loaded(LoadedAppState)
    
    public var id: Int {
        switch self {
            case .loading: 0
            case .err(_): 1
            case .loaded(_): 2
        }
    }
}

@MainActor
public class AppLoadingHandle : ObservableObject {
    public init() {
        
    }
    
    @Published public var phase: AppLoadingPhase = .loadingData;
    @Published public var state: AppLoadingStates = .loading;
    
    public func reset() {
        self.state = .loading;
        self.phase = .loadingData;
    }
    public func withError(err: any Error, animated: Bool) {
        optionalWithAnimation(isOn: animated) {
            self.objectWillChange.send();
            self.state = .err( .init(phase: self.phase, inner: err) )
        }
    }
    public func withLoaded(loaded: LoadedAppState, animated: Bool) {
        optionalWithAnimation(isOn: animated) {
            self.objectWillChange.send();
            self.state = .loaded(loaded)
        }
    }
    
    public func updatePhase(to: AppLoadingPhase, animated: Bool) {
        optionalWithAnimation(isOn: animated) {
            self.phase = to
        }
    }
}

public actor AppLoader {
    public init(handle: AppLoadingHandle) {
        self.handle = handle;
        self.log = Logger(subsystem: "com.exdisj.Ghosted", category: "App Loader")
    }
    
    private let handle: AppLoadingHandle;
    private let log: Logger;
    
    public func load(animated: Bool, beforeComplete: ((DataStack) async throws -> Void)? = nil) async {
        log.info("Begining app loading process.")
        await handle.reset();
        
        log.info("Loading data stack");
        await handle.updatePhase(to: .loadingData, animated: animated);
        
        let stack: DataStack;
        do {
            stack = try await DataStack.currentContainer();
        }
        catch let e {
            log.error("Unable to load stack due to error \(e)");
            
            await handle.withError(err: e, animated: animated);
            return;
        }
        
        log.info("Loading status reviewer");
        await handle.updatePhase(to: .reviewingApps, animated: animated);
        
        let reviewer = StatusReviewer(cx: stack.newBackgroundContext());
        
        log.info("Completed loading main components.");
        await handle.updatePhase(to: .wrappingUp, animated: animated);
        
        if let beforeComplete = beforeComplete {
            do {
                try await beforeComplete(stack);
            }
            catch let e {
                log.error("Post-load action could not be completed due to error \(e)")
                await handle.withError(err: e, animated: animated)
            }
        }
        
        log.info("Completed app loading");
        let completed = LoadedAppState(stack: stack, reviewer: reviewer);
        try? await Task.sleep(for: .seconds(0.5))
        await handle.withLoaded(loaded: completed, animated: animated);
    }
    public func reset() async throws {
        guard case .loaded(let loaded) = await handle.state else {
            await handle.reset();
            return;
        }
        
        try loaded.stack.viewContext.save();
        
        await handle.reset();
    }
    
    public func resetAndPerform(animated: Bool, action: @escaping (DataStack) async throws -> Void) async throws {
        try await self.reset();
        
        await self.load(animated: animated, beforeComplete: action);
    }
}

fileprivate struct AppLoaderKey : EnvironmentKey {
    static var defaultValue: AppLoader? {
        nil
    }
}
public extension EnvironmentValues {
    var appLoader: AppLoader? {
        get { self[AppLoaderKey.self] }
        set { self[AppLoaderKey.self] = newValue }
    }
}


