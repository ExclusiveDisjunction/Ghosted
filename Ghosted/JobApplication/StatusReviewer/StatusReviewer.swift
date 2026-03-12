//
//  StatusReviewer.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import CoreData
import Observation
import os

/// A collection of utilities for managing job applications based on their status.
@Observable
public final class StatusReviewer : Sendable {
    /// Constructs the status reviewer from a container, creating a background context from it.
    public init(container: NSPersistentContainer) {
        self.cx = container.newBackgroundContext();
    }
    /// Constructs the status reviewer from `NSManagedObjectContext` instances.
    /// - Parameters:
    ///     - cx: The background thread model context, used to process and update information off the main thread.
    public init(cx: NSManagedObjectContext) {
        self.cx = cx;
    }
    
    /// The context to peform computations with.
    @ObservationIgnored private let cx: NSManagedObjectContext;
    
    /// A set of ``JobApplicationState`` values, represented by their raw value, that the ``StatusReviewer``  should flag for updating.
    public static let interestingApplicationStates = Set<JobApplicationState.RawValue>(
        [
            JobApplicationState.applied,
            JobApplicationState.inInterview,
            JobApplicationState.underReview
        ].map { $0.rawValue }
    );
    
    /// Computes the ``JobApplication`` instances that need to be updated.
    /// - Parameters:
    ///     - log: The logger to display information, if any is needed.
    ///     - daysToCheck: The number of days between `relativeTo` and the ``JobApplication/lastStatusUpdated`` dates to mark for updating.
    ///     - relativeTo: The date to use as a reference point for the computation.
    ///     - calendar: The calendar to use for date math.
    /// - Throws: Any issues that Core Data occurs when fetching information.
    /// - Returns: A dictionary of object identifiers and an ``ApplicationStatusSnapshot``, used to update on the UI.
    ///
    /// This computation will take place on a background thread, perform asyncronously. Additionally, no ``JobApplication`` instances will be modified (read-only).
    ///
    /// The purpose of this method is to determine all outdated ``JobApplication``s. 'Outdated', in this context, refers to the state being applied, in interview, or under review, and updated at least `daysToCheck` days ago.
    /// If the application has no last updated date, it will fetch it and use ``JobApplication/appliedOn`` as the source of truth.
    public nonisolated func compute(log: Logger, daysToCheck: Int, relativeTo: Date, calendar: Calendar) async throws -> [NSManagedObjectID : ApplicationStatusSnapshot] {
        
        let toUpdate: [StaticApplicationStatusSnapshot] = try await cx.perform { [cx] in
            let req = JobApplication.fetchRequest();
            req.predicate = NSPredicate(format: "internalState IN %@", Self.interestingApplicationStates);
            
            let applications = try cx.fetch(req);
            
            var result = [StaticApplicationStatusSnapshot]();
            let today = calendar.startOfDay(for: relativeTo);
            for app in applications {
                let rawLastUpdated = app.lastStatusUpdated ?? app.appliedOn;
                
                let lastUpdated = calendar.startOfDay(for: rawLastUpdated)
                guard let daysBetween = calendar.dateComponents([.day], from: lastUpdated, to: today).day else {
                    log.warning("Could not determine days between today and last updated for application \(app.position)")
                    continue;
                }
                
                if daysBetween >= daysToCheck {
                    result.append(
                        StaticApplicationStatusSnapshot(
                            id: app.objectID,
                            position: app.position,
                            company: app.company,
                            current: app.state,
                            lastUpdate: lastUpdated
                        )
                    )
                }
            }
            
            return result;
        };
        
        return await Task { @MainActor [toUpdate] in
            var result = [NSManagedObjectID : ApplicationStatusSnapshot]();
            
            for app in toUpdate {
                result[app.id] = ApplicationStatusSnapshot(from: app);
            }
            
            return result;
        }.value;
    }
    
    /// A structure to name extracted resources from an ``ApplicationStatusSnapshot``.
    private struct UpdateRecord : Sendable, Identifiable {
        /// The object's ID
        let id: NSManagedObjectID;
        /// When true, only the last updated date should be modified.
        let markAsResolved: Bool;
        /// If  `markAsResolved` is `false`, the state of the ``JobApplication`` should be set to this value.
        let newStatus: JobApplicationState;
    }
    
    /// Updates job applications based on values from ``ApplicationStatusSnapshot``.
    /// - Parameters:
    ///     - results: The modified statuses to present to update from.
    ///     - calendar: The calendar to use for date math.
    /// - Throws: Any error that Core Data encounters while fetching ``JobApplication`` instances.
    /// - Warning: This method will make no validation to the ID values passed. This means that if the ID is not of the container, or is not a ``JobApplication`` instance, the method will crash the application.
    ///
    /// Within each ``ApplicationStatusSnapshot``, this method will determine records to be skipped. If the user did mark a snapshot as resolved (``ApplicationStatusSnapshot/updatedFlag``), nor change the state (``ApplicationStatusSnapshot/updateStateTo``),
    /// the record will be skipped. If the user changed the status, both the last updated date & application state will be changed. Otherwise, only the last updated date will change. After making all changes, the internal context will save.
    public nonisolated func completeUpdate(results: [NSManagedObjectID : ApplicationStatusSnapshot], calendar: Calendar) async throws {
        var keys = Set<NSManagedObjectID>();
        var processedResults = [UpdateRecord]();
        for (id, snapshot) in results {
            // Gotta love MainActor, so useful and so annoying
            // Anyways, if the updatedFlag is true, the user wants to disregard this warning. So, we will update the last updated to now.
            // If the user did not update at all (didUpdate is false), we skip it.
            let (skipped, markAsResolved, newStatus) = await MainActor.run { (!snapshot.didUpdate, snapshot.updatedFlag, snapshot.updateStateTo) };
            
            guard !skipped else {
                continue;
            }
            
            processedResults.append(
                UpdateRecord(id: id, markAsResolved: markAsResolved, newStatus: newStatus)
            )
            keys.insert(id);
        }
        
        let newDate = calendar.startOfDay(for: .now);
        try await cx.perform { [cx, processedResults, keys] in
            let req = JobApplication.fetchRequest();
            req.predicate = NSPredicate(format: "SELF IN %@", keys);
            
            let fetchedApps = try cx.fetch(req);
            let toUpdate = Dictionary(uniqueKeysWithValues: fetchedApps.map { ($0.objectID, $0) } );
            
            for record in processedResults {
                guard let targetApp = toUpdate[record.id] else {
                    continue;
                }
                
                targetApp.lastStatusUpdated = newDate;
                if !record.markAsResolved { //We need to update the state
                    targetApp.state = record.newStatus;
                }
            }
        }
        
        try cx.save();
    }
}
