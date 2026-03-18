//
//  UpdateWidget.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/17/26.
//

import WidgetKit
import CoreData
import ExDisj
import Combine
import os

public func makeAppliedOnPredicate(forDate: Date, calendar: Calendar) -> NSPredicate? {
    let begin = calendar.startOfDay(for: forDate)
    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: begin),
          let end = calendar.date(
            byAdding: .second,
            value: -1,
            to: nextDay
          ) else {
        return nil;
    }
    
    return NSPredicate(format: "internalAppliedOn BETWEEN %@", [begin as NSDate, end as NSDate]);
}

@discardableResult
func updateAppCountsWidget(cx: NSManagedObjectContext, forDate: Date = .now, calendar: Calendar, fileManager: FileManager = .default) async throws -> AppliedCountEntry {
    let entry = try await cx.perform { [cx] in
        let req = JobApplication.fetchRequest();
        guard let pred = makeAppliedOnPredicate(forDate: forDate, calendar: calendar) else {
            throw CocoaError(.validationInvalidDate)
        }
        req.predicate = pred;
        
        let count = try cx.count(for: req);
        
        return AppliedCountEntry(date: forDate, count: count)
    };
    
    try saveFileContents(data: entry, fileManager: fileManager, forWidget: .appliedCounts)
    return entry;
}
func updateAppCountsWidget(count: Int, forDate: Date = .now, fileManager: FileManager = .default)  throws {
    let entry = AppliedCountEntry(date: forDate, count: count);
    
    try saveFileContents(data: entry, fileManager: fileManager, forWidget: .appliedCounts)
}

public class NotificationToken : @unchecked Sendable {
    @MainActor
    public init(_ inner: NSObjectProtocol) {
        self.inner = inner;
    }
    
    deinit {
        self.cancel()
    }

    public static nonisolated func createAsync(center: NotificationCenter = .default, forName: NSNotification.Name?, object: (any Sendable)?, perform: @Sendable @escaping (Notification) -> Void) async -> NotificationToken? {
        return await MainActor.run {
            return create(center: center, forName: forName, object: object, perform: perform)
        }
    }
    public static nonisolated func createAsync(deposit: inout NotificationToken?, center: NotificationCenter = .default, forName: NSNotification.Name?, object: (any Sendable)?, perform: @Sendable @escaping (Notification) -> Void) async {
        let token = await MainActor.run {
            return create(center: center, forName: forName, object: object, perform: perform)
        }
        
        deposit = token;
    }
    @MainActor
    public static func create(center: NotificationCenter = .default, forName: NSNotification.Name?, object: Any?, perform: @Sendable @escaping (Notification) -> Void) -> NotificationToken {
        let token = center.addObserver(forName: forName, object: object, queue: OperationQueue.main, using: perform);
        
        return NotificationToken(token)
    }
    
    @MainActor
    private let inner: NSObjectProtocol;
    
    public nonisolated func cancel() {
        DispatchQueue.main.async {
            NotificationCenter.default.removeObserver(self.inner)
        }
    }
}

public final actor WidgetDataManager : Sendable {
    public init(using: DataStack, calendar: Calendar, log: Logger?, onUpdate: (@Sendable (Int) async -> Void)? = nil) async {
        self.log = log;
        self.calendar = calendar;
        self.cx = using.newBackgroundContext();
        self.cancel = nil;
        self.onUpdate = onUpdate;
        
        let vcx = using.viewContext;
        self.cancel = await NotificationToken.createAsync(forName: .NSManagedObjectContextDidSave, object: vcx) { [weak self, log] note in
            Self.handleSave(log: log, note: note, inner: self)
        }
    }
    
    private let log: Logger?;
    private let cx: NSManagedObjectContext;
    private let calendar: Calendar;
    private let onUpdate: (@Sendable (Int) async -> Void)?;
    private var cancel: NotificationToken?;
    private var lastCount: Int? = nil;
    
    private struct UpdateError : Error { }
    
    private func determineIfApplicationsNeedUpdate(forDate: Date, update: Set<NSManagedObjectID>, lastCount: Int) async throws -> Int? {
        let count: Int? = try await cx.perform { [cx, calendar, log, update] in
            guard let datePred = makeAppliedOnPredicate(forDate: forDate, calendar: calendar) else {
                log?.error("Unable to get date predicate for update.");
                return nil;
            }
            
            let req = JobApplication.fetchRequest();
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                datePred,
                NSPredicate(format: "SELF IN %@", update as NSSet)
            ])
            
            return try cx.count(for: req);
        };
        
        guard let count = count else {
            log?.error("Unable to determine applications count for today.");
            throw UpdateError();
        }
        
        guard lastCount != count else {
            return nil; //Nothing to update
        }
        
        return count;
    }
    
    // TODO: Write unit tests that determine if the system is working properly. 
    
    private func proccessChanges(update: [NSManagedObjectID], hadDeleted: Bool) async {
        let update = Set(update);
        
        guard hadDeleted || !update.isEmpty else {
            log?.info("No applications were deleted or updated, so ignoring notification")
            return;
        }
        
        let date = Date.now;
        
        /*
         If we have deleted elements, we need to update regardless.
         But, if we have updated elements, and they have
         */
        
        let willUpdate: Bool;
        var newCount: Int? = nil; // Will be set if the counts is already computed
        if hadDeleted {
            willUpdate = true;
        }
        else if !update.isEmpty {
            if let lastCount = lastCount {
                do {
                    let newCount = try await determineIfApplicationsNeedUpdate(forDate: date, update: update, lastCount: lastCount);
                    willUpdate = newCount != nil;
                    self.lastCount = newCount;
                }
                catch let e {
                    log?.error("Unable to fetch application counts due to error \(e.localizedDescription)");
                    return;
                }
            }
            else {
                willUpdate = true;
            }
        }
        else {
            willUpdate = false;
        }
        
        let resultingCount: Int?;
        do {
            if let newCount = newCount {
                try updateAppCountsWidget(count: newCount, forDate: date);
                resultingCount = newCount;
            }
            else if willUpdate {
                resultingCount = try await updateAppCountsWidget(cx: cx, forDate: date, calendar: calendar).count;
            }
            else {
                resultingCount = nil;
            }
        }
        catch let e {
            log?.error("Unable to update the widget due to error \(e)")
            resultingCount = nil;
        }
        
        if let resultingCount = resultingCount, let postAction = self.onUpdate {
            await postAction(resultingCount)
        }
    }
    
    private static nonisolated func handleSave(log: Logger?, note: Notification, inner: WidgetDataManager?) {
        guard let inner = inner else {
            log?.warning("No widget manager to update, skipping notification.");
            return;
        }
        guard let info = note.userInfo else {
            log?.warning("Got notification to update widget information, but there is no payload.");
            return;
        }
        
        log?.info("Processing message to update widgets, if target information is obtained.");
        
        let inserted = (info[NSInsertedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        let updated = (info[NSUpdatedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        let deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        
        let updatedTargets = inserted.union(updated)
            .filter { $0.entity.name == "JobApplication" }
            .map { $0.objectID };
        let hadDeleted = !deleted
            .filter { $0.entity.name == "JobApplication" }
            .isEmpty
        
        log?.info("Processing update widget message, got \(updatedTargets.count) updated, had deleted? \(hadDeleted)");
        
        Task {
            await inner.proccessChanges(update: updatedTargets, hadDeleted: hadDeleted)
        }
    }
    
    
}
