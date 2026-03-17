//
//  StatusReviewer.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import Foundation
import Testing
import CoreData
import os
import ExDisj

import Ghosted

struct StatusReviewFiller : ContainerDataFiller {
    func fill(context: NSManagedObjectContext) throws {
        let states: [JobApplicationState] = [
            .applied,
            .applied,
            .inInterview,
            .inInterview,
            .underReview,
            .rejected
        ];
        
        let calendar = Calendar.current;
        let targetDate = calendar.date(byAdding: .day, value: -15, to: calendar.startOfDay(for: .now))!;
        
        for (i, state) in states.enumerated() {
            let job = JobApplication(context: context);
            job.position = "Position \(i + 1)"
            job.company = "Company \(i + 1)"
            job.state = state
            job.appliedOn = targetDate
            job.lastStatusUpdated = targetDate
            job.kind = .fullTime
            job.locationKind = .onSite
        }
    }
}

@Suite("StatusReviewerTests")
struct StatusReviewerTests : Sendable {
    static func prepare() async throws -> DataStack {
        let container = try await DataStack(
            desc: .builder(
                filler: StatusReviewFiller(),
                backing: .inMemory()
            )
        )
        
        return container;
    }
    
    init() async throws {
        container = try await Self.prepare();
        cx = container.viewContext;
        
        cal = Calendar.current;
        log = Logger(subsystem: "com.exdisj.Ghosted", category: "Unit Testing")
        
        reviewer = StatusReviewer(container: container, logger: log);
        
        targets = try await reviewer.compute(daysToCheck: 10, relativeTo: .now, calendar: cal);
    }
    
    let container: DataStack;
    let cx: NSManagedObjectContext;
    let reviewer: StatusReviewer;
    let targets: StatusReviewer.ById;
    let cal: Calendar;
    let log: Logger;
    
    @Test("fetchingAndComputation")
    func fetchingAndComputation() async throws {
        try await cx.perform { [cx] in
            let req = JobApplication.fetchRequest();
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "lastStatusUpdated != nil"),
                NSPredicate(format: "internalState IN %@", StatusReviewer.interestingApplicationStates)
            ]);
            
            let fetched = try cx.fetch(req);
            try #require(!fetched.isEmpty)
            
            for app in fetched {
                guard let snapshot = targets[app.objectID] else {
                    #expect(Bool(false), "Unable to get the snapshot for \(app.position)");
                    continue;
                }
                
                #expect(snapshot.position == app.position)
                #expect(snapshot.company == app.company)
                #expect(snapshot.currentState == app.state)
                #expect(snapshot.id == app.objectID)
            }
        }
    }
    
    @Test("updatingWithNewStates")
    func updatingWithNewStates() async throws {
        // We will set all to ghosted, updated today.
        let ids = await MainActor.run {
            var result = [NSManagedObjectID]();
            for (id, snapshot) in targets {
                snapshot.updateStateTo = .ghosted;
                result.append(id)
                
                #expect(snapshot.didUpdate);
            }
            
            return result;
        }
        
        try await reviewer.completeUpdate(results: targets, calendar: cal);
        
        let today = cal.startOfDay(for: .now);
        await Task { @MainActor [cx, ids] in
            await cx.perform { [cx, ids] in
                for id in ids {
                    let targetObject = cx.object(with: id) as! JobApplication;
                    
                    let updatedDate = cal.startOfDay(for: targetObject.lastStatusUpdated ?? .distantPast);
                    
                    #expect(updatedDate == today)
                    #expect(targetObject.state == .ghosted)
                }
            }
        }.value
    }
    
    @Test("updatingWithIgnore")
    func updatingWithIgnore() async throws {
        // We will flag each one as updated, which we expect to only update the lastUpdated day, but keep the state.
        let ids = await MainActor.run {
            var result = [NSManagedObjectID]();
            for (id, snapshot) in targets {
                snapshot.updatedFlag = true;
                result.append(id)
                
                #expect(snapshot.didUpdate);
            }
            
            return result;
        }
        
        try await reviewer.completeUpdate(results: targets, calendar: cal);
        
        let today = cal.startOfDay(for: .now);
        await Task { @MainActor [cx, ids, targets] in
            await cx.perform { [cx, ids, targets] in
                for id in ids {
                    let targetObject = cx.object(with: id) as! JobApplication;
                    let snapshot = targets[id]!;
                    
                    let updatedDate = cal.startOfDay(for: targetObject.lastStatusUpdated ?? .distantPast);
                    
                    #expect(updatedDate == today)
                    #expect(targetObject.state == snapshot.updateStateTo)
                }
            }
        }.value
    }
    
    @Test("updatingWithNoChange")
    func updatingWithNoChange() async throws {
        // We will perform no change, and expect that nothing has changed.
        try await reviewer.completeUpdate(results: targets, calendar: cal);
        
        await Task { @MainActor [cx, targets] in
            let updatedTargets = targets.map { ($0.key, $0.value.currentState, $0.value.lastUpdated)}
            
            await cx.perform { [cx, updatedTargets] in
                for (id, currentState, lastUpdated) in updatedTargets {
                    let targetObject = cx.object(with: id) as! JobApplication;
                    
                    let updatedDate = cal.startOfDay(for: targetObject.lastStatusUpdated ?? .distantPast);
                    let expectedDate = cal.startOfDay(for: lastUpdated);
                    
                    #expect(updatedDate == expectedDate);
                    #expect(targetObject.state == currentState)
                }
            }
        }.value
    }
    
    @Test("IDs-Prepare")
    func idPrepare() async throws {
        let bySection = StatusReviewerSheet.prepare(from: targets);
        
        let totalCount = await cx.perform {
            var totalCount = 0;
        
            for (section, applications) in bySection {
                for app in applications {
                    totalCount += 1;
                    
                    let targetObject = cx.object(with: app.id) as! JobApplication;
                    #expect(targetObject.state == section);
                }
            }
            
            return totalCount;
        }
        
        #expect(totalCount == 5);
        
        // Now we have to demangle it back into targets.
        
        let demangled = StatusReviewerSheet.demangle(bySection: bySection);
        await MainActor.run {
            #expect(demangled == targets);
        }
    }
    
    @Test("MoveToSection")
    func moveToSection() async throws {
        
    }
}
