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
        
    }
}

/*
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}
 */

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
