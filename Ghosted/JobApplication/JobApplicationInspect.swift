//
//  JobApplicationEdit.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import ExDisj

/// A view that allows for the inspection of a ``JobApplication``
public struct JobApplicationInspect : View {
    public init(_ source: JobApplication) {
        self.source = source;
    }
    
    private let source: JobApplication;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        Form {
            Section {
                LabeledContent("Position", value: source.position)
                LabeledContent("Company", value: source.company)
            }
            
            Section {
                LabeledContent("Applied On", value: source.appliedOn.formatted(date: .numeric, time: .shortened))
                LabeledContent("Status") {
                    DisplayableVisualizer(value: source.state)
                }
            }
            
            Section {
                LabeledContent("Position Kind") {
                    DisplayableVisualizer(value: source.kind)
                }
                
                LabeledContent("Location") {
                    EmptyValuePlaceholder(source.location)
                }
                
                LabeledContent("Job Kind") {
                    DisplayableVisualizer(value: source.locationKind)
                }
            }
            
            Section {
                LabeledContent("Website") {
                    EmptyValuePlaceholder(source.website)
                }
                
                LabeledContent("Notes") {
                    EmptyValuePlaceholder(source.notes)
                }
            }
        }
    }
}

extension JobApplication : InspectableElement {
    @MainActor
    public func makeInspectView() -> JobApplicationInspect {
        JobApplicationInspect(self)
    }
}
extension JobApplication : TypeTitled {
    public static var typeDisplay: TypeTitleStrings {
        return TypeTitleStrings(
            singular: "Job Application",
            plural: "Job Applications",
            inspect: "Inspect Job Application",
            edit: "Edit Job Application",
            add: "Add Job Application"
        )
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<JobApplication>(sortDescriptors: [])
    var apps: FetchedResults<JobApplication>;
    
    ElementInspector(data: apps.first!)
}
