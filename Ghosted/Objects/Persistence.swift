//
//  Persistence.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import ExDisj
import CoreData
import SwiftUI

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

public struct VarianceContainerFiller : ContainerDataFiller {
    public func fill(context: NSManagedObjectContext) throws {
        var rand = SystemRandomNumberGenerator();
        let calendar = Calendar.current;
        
        for i in 1...30 {
            let app = JobApplication(context: context);
            guard let date = calendar.date(
                byAdding: .day,
                value: Int.random(in: (-31)...(-2), using: &rand),
                to: .now,
            ) else {
                continue;
            }
            
            app.position = "Position \(i)";
            app.company = "Company \(i)";
            app.appliedOn = date;
            app.kind = .fullTime;
            app.locationKind = .remote;
            app.location = "";
            app.state = JobApplicationState(rawValue: Int16.random(in: 0...5, using: &rand))!;
        }
    }
}

public struct MarketingContainerFiller : ContainerDataFiller {
    public func fill(context: NSManagedObjectContext) throws {
        var rand = SystemRandomNumberGenerator();
        let calendar = Calendar.current;
        
        let samples: [(String, String, JobApplicationState)] = [
            ("Senior Product Designer", "Stellar Cloud Systems", .inInterview),
            ("Junior Software Engineer", "GreenLoop Energy", .applied),
            ("Marketing Coordinator", "Peak Performance Athletics", .rejected),
            ("Data Analyst", "Silverline Logistics", .underReview),
            ("UX Researcher", "Blue Marble Media", .ghosted),
            ("Operations Manager", "Horizon FinTech", .accepted),
            ("Account Executive", "Pulse Health Tech", .underReview),
            ("Creative Director", "Neon Agency", .inInterview),
            ("Full Stack Developer", "SwiftStream Apps", .applied),
            ("Customer Success Lead", "Anchor Maritime", .ghosted),
            ("Human Resources Generalist", "EverGrow Organics", .rejected)
        ];
        
        for (name, company, status) in samples {
            guard let date = calendar.date(
                byAdding: .day,
                value: Int.random(in: (-64)...0, using: &rand),
                to: .now,
            ) else {
                continue;
            }
            
            let app = JobApplication(context: context);
            app.position = name;
            app.company = company;
            app.lastStatusUpdated = date;
            app.appliedOn = date;
            app.state = status;
            app.location = "";
            app.locationKind = .remote;
        }
        
        let fullDetails = JobApplication(context: context);
        fullDetails.position = "Technical Writer"
        fullDetails.company = "Orbit Satellite Co.";
        fullDetails.state = .underReview;
        fullDetails.lastStatusUpdated = .now;
        fullDetails.appliedOn = .now;
        fullDetails.locationKind = .onSite;
        fullDetails.location = "New York, NY";
        fullDetails.website = URL(string: "https://orbitsatellite.com")!;
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
public struct VarianceSampleData: PreviewModifier {
    public static func makeSharedContext() async throws -> DataStack {
        try await DataStack(
            desc: .builder(
                filler: VarianceContainerFiller(),
                backing: .inMemory()
            )
        )
    }
    
    public func body(content: Content, context: DataStack) -> some View {
        content
            .environment(\.dataStack, context)
    }
}

@available(macOS 15, iOS 18, *)
public extension PreviewTrait where T == Preview.ViewTraits {
    static let sampleData: Self = .modifier(DebugSampleData())
    static let varianceSampleData: Self = .modifier(VarianceSampleData())
}
