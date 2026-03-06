//
//  Persistence.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

@preconcurrency import CoreData
import Combine
import SwiftUI

/// A type that can be used to fill in dummy data for a `NSManagedObjectContext`.
public protocol ContainerDataFiller {
    /// Given the `context`, fill out the container's values.
    /// - Parameters:
    ///     - context: The `NSManagedObjectContext` to insert to.
    func fill(context: NSManagedObjectContext) throws;
}

public struct DebugContainerFiller : ContainerDataFiller {
    public func fill(context: NSManagedObjectContext) throws {
        let app1 = JobApplication(context: context);
        app1.appliedOn = .now;
        app1.company = "ExDisj";
        app1.kind = .fullTime;
        app1.locationKind = .remote;
        app1.location = "";
        app1.position = "Junior Developer";
        app1.state = .underReview;
        
        let app2 = JobApplication(context: context);
        app2.appliedOn = .now;
        app2.company = "ExDisj";
        app2.kind = .partTime;
        app2.locationKind = .hybrid;
        app2.location = "Lakeland, FL";
        app2.position = "App Developer";
        app2.state = .rejected;
    }
}

public class DataStack : ObservableObject, @unchecked Sendable {
    public static let shared: DataStack = DataStack()
    public static let containerName = "Ghosted";
    
    private var _persistentContainer: NSPersistentCloudKitContainer? = nil;
    private var _debugContainer: NSPersistentCloudKitContainer? = nil;
    
    public var currentContainer: NSPersistentContainer {
        #if DEBUG
        self.debugContainer
        #else
        self.persistentContainer
        #endif
    }
    
    public var persistentContainer: NSPersistentCloudKitContainer {
        get {
            if let container = self._persistentContainer {
                return container;
            }
            
            let container = NSPersistentCloudKitContainer(name: Self.containerName);
            
            container.loadPersistentStores { _, error in
                if let error {
                    fatalError("Unable to load persistent store due to error \(error)")
                }
                
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
            }
            
            self._persistentContainer = container;
            return container;
        }
    }
    
    public var debugContainer: NSPersistentContainer {
        get {
            if let container = self._debugContainer {
                return container;
            }
            
            let container = NSPersistentCloudKitContainer(name: Self.containerName);
            
            let desc = NSPersistentStoreDescription();
            desc.url = URL(fileURLWithPath: "/dev/null");
            desc.shouldAddStoreAsynchronously = false;
            container.persistentStoreDescriptions = [desc]
            
            container.loadPersistentStores { desc, error in
                if let error = error {
                    fatalError("Failed to make in memory store: \(error)")
                }
                
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
                
                do {
                    try DebugContainerFiller().fill(context: container.viewContext)
                    try container.viewContext.save();
                } catch let e {
                    fatalError("Unable to fill the debug container: \(e)")
                }
            }
            
            _debugContainer = container;
            return container
        }
    }
    
    /// Creates an empty, in memory persistent container on each call.
    /// Every call to this variable results in a new, isolated container.
    public var emptyDebugContainer : NSPersistentContainer {
        get {
            let bundle = Bundle(for: DataStack.self);
            
            guard
                let modelURL = bundle.url(forResource: Self.containerName, withExtension: "mom"),
                let model = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError("Unable to load the managed object model.");
            }
            
            let container = NSPersistentContainer(name: Self.containerName, managedObjectModel: model);
            
            let desc = NSPersistentStoreDescription();
            desc.type = NSInMemoryStoreType;
            desc.shouldAddStoreAsynchronously = false;
            container.persistentStoreDescriptions = [desc]
            
            container.loadPersistentStores { desc, error in
                if let error = error {
                    fatalError("Failed to make in memory store: \(error)")
                }
                
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
            }
            
            return container
        }
    }
    
    private init() {
        
    }
}

public struct DebugSampleData: PreviewModifier {
    public static func makeSharedContext() throws -> DataStack {
        DataStack.shared
    }
    
    public func body(content: Content, context: DataStack) -> some View {
        content
            .environment(\.managedObjectContext, context.debugContainer.viewContext)
    }
}

@available(macOS 15, iOS 18, *)
public extension PreviewTrait where T == Preview.ViewTraits {
    static let sampleData: Self = .modifier(DebugSampleData())
}
