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

public func updateAppCountsWidget(using: DataStack, forDate: Date = .now, calendar: Calendar, fileManager: FileManager = .default) async throws {
    let cx = using.newBackgroundContext();
    
    let begin = calendar.startOfDay(for: forDate)
    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: begin),
          let end = calendar.date(
                byAdding: .second,
                value: -1,
                to: nextDay
          ) else {
              throw CocoaError(.validationInvalidDate)
    }
    
    let entry = try await cx.perform { [cx, begin, end] in
        let req = JobApplication.fetchRequest();
        req.predicate = NSPredicate(format: "internalAppliedOn BETWEEN %@", [begin as NSDate, end as NSDate]);
        
        let count = try cx.count(for: req);
        
        return AppliedCountEntry(date: forDate, count: count)
    };
    
    try saveFileContents(data: entry, fileManager: fileManager, forWidget: .appliedCounts)
}

@Observable
public final class WidgetDataManager : Sendable {
    @MainActor
    public init(using: DataStack, calendar: Calendar, log: Logger?) {
        self.log = log;
        self.calendar = calendar;
        self.cx = using.newBackgroundContext();
        self.cancel = nil;
        
        let vcx = using.viewContext;
        
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: cx,
            queue: OperationQueue.main
        ) { [weak self] note in
            self?.handleSave(note: note)
        }
    }
    
    private let log: Logger?;
    private let cx: NSManagedObjectContext;
    private let calendar: Calendar;
    @MainActor
    private var cancel: AnyCancellable?;
    
    private func handleSave(note: Notification) {
        guard let info = note.userInfo else {
            log?.warning("Got notification to update widget information, but there is no payload.");
            return;
        }
        
        log?.info("Processing message to update widgets, if target information is obtained.");
        
        let today = calendar.startOfDay(for: .now);
    }
}
