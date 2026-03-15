//
//  Persistence.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import ExDisj
import CoreData
import SwiftUI

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

//Ghosted specific
public let modelName: String = "Ghosted";

extension StoreDescription {
    public static func inMemory(automaticMigrations: Bool = true) -> InMemoryStoreDescription where Self == InMemoryStoreDescription {
        return InMemoryStoreDescription(modelName: Ghosted.modelName, automaticLightweightMigrations: automaticMigrations)
    }
    public static func standard(automaticMigrations: Bool = true, paths: [URL]) -> StandardStoreDescription where Self == StandardStoreDescription {
        return StandardStoreDescription(modelUrl: paths, modelName: Ghosted.modelName, automaticLightweightMigrations: automaticMigrations)
    }
    public static func standard(automaticMigrations: Bool = true) throws -> StandardStoreDescription where Self == StandardStoreDescription {
        guard let url = URL(
            string: "\(Ghosted.modelName).sqlite",
            relativeTo: try FileManager.default
                .url(
                    for: .libraryDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
        ) else {
            throw CocoaError(.fileWriteNoPermission)
        }
        
        return StandardStoreDescription(modelUrl: [url], modelName: Ghosted.modelName, automaticLightweightMigrations: automaticMigrations)
    }
}

public extension DataStack {
    static func standardContainer() async throws -> DataStack {
        try await DataStack(
            desc: .standard()
        )
    }
    static func debugContainer() async throws -> DataStack {
        try await DataStack(
            desc: .builder(
                filler: DebugContainerFiller(),
                backing: .inMemory()
            )
        )
    }
    static func emptyDebugContainer() async throws -> DataStack {
        try await DataStack(
            desc: .inMemory()
        )
    }
    
    static func currentContainer() async throws -> DataStack {
#if DEBUG
        return try await Self.debugContainer()
#else
        return try await Self.standardContainer()
#endif
    }
}

public struct DebugSampleData: PreviewModifier {
    public static func makeSharedContext() async throws -> DataStack {
        try await DataStack.debugContainer()
    }
    
    public func body(content: Content, context: DataStack) -> some View {
        content
            .environment(\.dataStack, context)
    }
}

@available(macOS 15, iOS 18, *)
public extension PreviewTrait where T == Preview.ViewTraits {
    static let sampleData: Self = .modifier(DebugSampleData())
}
