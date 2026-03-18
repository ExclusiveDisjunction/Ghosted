//
//  WidgetOps.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/18/26.
//

import Testing
import Ghosted
import CoreData
import ExDisj
import os
import XCTest

struct WidgetDataFiller : ContainerDataFiller {
    func fill(context: NSManagedObjectContext) throws {
        for i in 1...4 {
            guard let date = Calendar.current.date(byAdding: .day, value: Int.random(in: (-5)...(-2)), to: .now) else {
                continue;
            }
            let job = JobApplication(context: context);
            
            job.position = "Position \(i)";
            job.company = "Company \(i)"
            job.state = .applied;
            job.lastStatusUpdated = date;
            job.appliedOn = date;
            job.kind = .fullTime
            job.locationKind = .onSite;
        }
    }
}

@Suite("WidgetOps")
struct WidgetOps {
    init() async throws {
        
        cal = Calendar.current;
        log = Logger(subsystem: "com.exdisj.Ghosted", category: "Unit Testing")
    }
    
    let cal: Calendar;
    let log: Logger;
    
    private func prepare() async throws -> (DataStack, NSManagedObjectContext, WidgetDataManager) {
        let stack = try await DataStack(
            desc: .builder(
                filler: WidgetDataFiller(),
                backing: .inMemory()
            )
        )
        let cx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType);
        cx.persistentStoreCoordinator = stack.coordinator;
        stack.viewContext.automaticallyMergesChangesFromParent = true;
        
        let manager = await WidgetDataManager(using: stack, calendar: cal, log: log);
        try await manager.prepare(forDate: .now);
        
        return (stack, cx, manager);
    }
    
    @Test("noAction")
    func noAction() async throws {
        // Do nothing, verify that it does not run.
        let (stack, cx, manager) = try await prepare();
        
        try await Task.sleep(for: .seconds(0.3)); //Ensure it is loaded
        await confirmation(expectedCount: 0) { confirm in
            await manager.withUpdateAction { count in
                confirm()
            }
        };
        
        let (asyncStream, continuation) = AsyncStream<Int>.makeStream();
        await manager.withUpdateAction { count in
            continuation.yield(count)
        }
        var asyncIter = asyncStream.makeAsyncIterator();
        
        try await cx.perform { [cx] in
            let newApp = JobApplication(context: cx);
            newApp.company = "Test";
            newApp.position = "test";
            newApp.appliedOn = .now;
            newApp.lastStatusUpdated = newApp.appliedOn;
            newApp.state = .applied;
            newApp.location = "";
            newApp.locationKind = .onSite;
            
            try cx.save();
        }
        try stack.viewContext.save();
        
        try await Task.sleep(for: .seconds(0.3)); //Ensure it is loaded
        let runExepctation = XCTestExpectation(description: "Obtain the updated count");
        let runTask = Task { [runExepctation] in
            let count = await asyncIter.next();
            runExepctation.fulfill();
            return count;
        };
        
        let waitingResult = await XCTWaiter.fulfillment(of: [runExepctation], timeout: 10.0);
        try #require( waitingResult == .completed );
        
        let expectedCount = await runTask.value;
        
    }
}
