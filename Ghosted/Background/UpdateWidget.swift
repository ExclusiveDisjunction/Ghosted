//
//  UpdateWidget.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/17/26.
//

import WidgetKit
import CoreData
import ExDisj

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
