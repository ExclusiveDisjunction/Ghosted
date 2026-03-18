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

public actor NotificationToken {
    private struct InnerToken : @unchecked Sendable {
        let token: NSObjectProtocol;
    }
    
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        MainActor.sharedUnownedExecutor
    }
    
    @MainActor
    public init(_ inner: NSObjectProtocol, center: NotificationCenter) {
        debugPrint("Opening notification token");
        
        let token = InnerToken(token: inner);
        self.tokenBox = .init(initialState: token);
        self.center = center;
    }
    deinit {
        debugPrint("Closing notification token")
        self.cancel()
    }
    
    public static nonisolated func createAsync(center: NotificationCenter = .default, forName: NSNotification.Name?, object: (any Sendable)?, perform: @Sendable @escaping (Notification) -> Void) async -> NotificationToken? {
        return await MainActor.run {
            return create(center: center, forName: forName, object: object, perform: perform)
        }
    }
    @MainActor
    public static func create(center: NotificationCenter = .default, forName: NSNotification.Name?, object: Any?, perform: @Sendable @escaping (Notification) -> Void) -> NotificationToken {
        let token = center.addObserver(forName: forName, object: object, queue: OperationQueue.main, using: perform);
        
        return NotificationToken(token, center: center)
    }
    
    private let center: NotificationCenter;
    private let tokenBox: OSAllocatedUnfairLock<InnerToken?>;
    
    public nonisolated func cancel() {
        let token = tokenBox.withLock {
            let old = $0;
            $0 = nil;
            return old;
        };
        
        if let token {
            center.removeObserver(token.token);
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
            log?.debug("Obtained notification, has self? \(self != nil)")
            Self.handleSave(log: log, note: note, inner: self)
        }
        
        log?.info("Widget data manager is configured, listening for notifications.");
    }
    
    private let log: Logger?;
    private let cx: NSManagedObjectContext;
    private let calendar: Calendar;
    private var onUpdate: (@Sendable (Int) async -> Void)?;
    private var cancel: NotificationToken?;
    
    private struct UpdateError : Error { }
    
    public func withUpdateAction(action: @Sendable @escaping (Int) async -> Void) {
        self.onUpdate = action;
    }
    public func withUpdateAction() {
        self.onUpdate = nil;
    }
    
    private func determineIfApplicationsNeedUpdate(forDate: Date, update: Set<NSManagedObjectID>) async throws -> Bool {
        return try await cx.perform { [cx, calendar, log, update] in
            guard let datePred = makeAppliedOnPredicate(forDate: forDate, calendar: calendar) else {
                log?.error("Unable to get date predicate for update.");
                return true;
            }
            
            let req = JobApplication.fetchRequest();
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                datePred,
                NSPredicate(format: "SELF IN %@", update as NSSet)
            ])
            
            return try cx.count(for: req) != 0;
        };
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
        if hadDeleted {
            willUpdate = true;
        }
        else if !update.isEmpty {
            do {
                willUpdate = try await determineIfApplicationsNeedUpdate(forDate: date, update: update);
            }
            catch let e {
                log?.error("Unable to fetch application counts due to error \(e.localizedDescription)");
                return;
            }
        }
        else {
            willUpdate = false;
        }
        
        let resultingCount: Int?;
        do {
            if willUpdate {
                log?.info("Notification determined that an update is needed.");
                resultingCount = try await updateAppCountsWidget(cx: cx, forDate: date, calendar: calendar).count;
            }
            else {
                log?.info("Notification determined that no update is needed.");
                resultingCount = nil;
            }
        }
        catch let e {
            log?.error("Unable to update the widget due to error \(e)")
            resultingCount = nil;
        }
        
        if let resultingCount = resultingCount {
            if let postAction = self.onUpdate {
                await postAction(resultingCount)
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines();
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
    
    @discardableResult
    public func prepare(forDate: Date) async throws -> Int {
        let result = try await updateAppCountsWidget(cx: cx, forDate: forDate, calendar: calendar).count;
        
        if let postAction = self.onUpdate {
            await postAction(result)
        }
        
        WidgetCenter.shared.reloadAllTimelines();
        
        return result;
    }
    
}
