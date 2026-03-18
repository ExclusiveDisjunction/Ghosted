//
//  Widgets.swift
//  Widgets
//
//  Created by Hollan Sellars on 3/17/26.
//

import WidgetKit
import SwiftUI



extension AppliedCountEntry : TimelineEntry {
    
}

struct AppliedCountProvider : TimelineProvider {
    func placeholder(in context: Context) -> AppliedCountEntry {
        AppliedCountEntry(date: .now, count: 7)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AppliedCountEntry) -> Void) {
        let entry = placeholder(in: context);
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AppliedCountEntry>) -> Void) {
        var entries: [AppliedCountEntry] = [];
        do {
            if let loadedEntry: AppliedCountEntry = try getFileContents(forWidget: .appliedCounts) {
                entries.append(loadedEntry);
            }
            let calendar = Calendar.current;
            
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) else {
                #if DEBUG
                print("Unable to get tomorrow")
                #endif
                
                completion(.init(entries: [], policy: .never))
                return;
            }
            
            entries.append(.init(date: tomorrow, count: 0))
        }
        catch let e {
#if DEBUG
            print("Unable to load the widget contents, \(e)")
#endif
        }
        
        completion(.init(entries: entries, policy: .never))
    }
}

struct WidgetsEntryView : View {
    let entry: AppliedCountEntry;

    var body: some View {
        VStack(alignment: .leading) {
            Text("Applications Today")
                .font(.title2)
            
            HStack {
                Spacer()
                Text(entry.count, format: .number)
                    .font(.system(size: 50))
            }
        }.foregroundStyle(.white)
    }
}

struct Widgets: Widget {
    let kind: String = "Widgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AppliedCountProvider()) { entry in
            WidgetsEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color("WidgetColor")
                }
        }
        .configurationDisplayName("Applied Job Count")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    Widgets()
} timeline: {
    AppliedCountEntry(date: .now, count: 7)
    AppliedCountEntry(date: .now, count: 15)
    AppliedCountEntry(date: .now, count: 0)
}
