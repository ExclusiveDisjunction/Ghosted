//
//  JobApplication.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

public enum JobApplicationState : Int16, Equatable, Hashable, Codable, Sendable, CaseIterable, Identifiable {
    case applied = 0
    case underReview = 1
    case inInterview = 2
    case rejected = 3
    case accepted = 4
    case ghosted = 5
    
    public var id: Self { self }
    
    public var color: Color {
        switch self {
            case .applied: Color.primary
            case .underReview:
                fallthrough
            case .inInterview:
                Color.blue
            case .rejected:
                Color.red
            case .accepted:
                Color.green
            case .ghosted:
                Color.gray
        }
    }
}
extension JobApplicationState : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .applied: "Applied"
            case .underReview: "Under Review"
            case .inInterview: "In Interview"
            case .rejected: "Rejected"
            case .accepted: "Accepted"
            case .ghosted: "Ghosted"
        }
    }
}

public enum JobLocation : Int16, Equatable, Hashable, Codable, Sendable, CaseIterable, Identifiable {
    case onSite = 0
    case hybrid = 1
    case remote = 2
    
    public var id: Self { self }
}
extension JobLocation : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .onSite: "On-Site"
            case .hybrid: "Hybrid"
            case .remote: "Remote"
        }
    }
}

public enum JobKind : Int16, Equatable, Hashable, Codable, Sendable, CaseIterable, Identifiable {
    case fullTime = 0
    case partTime = 1
    case seasonal = 2
    case contractor = 3
    
    public var id: Self { self }
}
extension JobKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .fullTime: "Full Time"
            case .partTime: "Part Time"
            case .seasonal: "Seasonal"
            case .contractor: "Contractor/Freelance"
        }
    }
}

public extension JobApplication {
    var position: String {
        get { self.internalPosition ?? String() }
        set { self.internalPosition = newValue }
    }
    var company: String {
        get { self.internalCompany ?? String() }
        set { self.internalCompany = newValue }
    }
    var location: String {
        get { self.internalLocation ?? String() }
        set { self.internalLocation = newValue }
    }
    var appliedOn: Date {
        get { self.internalAppliedOn ?? .distantPast }
        set { self.internalAppliedOn = newValue }
    }
    var state: JobApplicationState {
        get { JobApplicationState(rawValue: self.internalState) ?? .applied }
        set { self.internalState = newValue.rawValue }
    }
    var kind: JobKind {
        get { JobKind(rawValue: self.internalKind) ?? .fullTime }
        set { self.internalKind = newValue.rawValue }
    }
    var locationKind: JobLocation {
        get { JobLocation(rawValue: self.internalLocationKind) ?? .onSite }
        set { self.internalLocationKind = newValue.rawValue }
    }
    var notes: String {
        get { self.internalNotes ?? String() }
        set { self.internalNotes = newValue }
    }
    
    private func validateValues() throws(ValidationFailure) {
        var builder = ValidationFailureBuilder();
        if position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            builder.add(prop: "Position", reason: .empty)
        }
        if company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            builder.add(prop: "Company", reason: .empty)
        }
        
        if let failure = builder.build() {
            throw failure;
        }
    }
    
    override func validateForInsert() throws {
        try super.validateForInsert();
            
        try validateValues()
    }
    override func validateForUpdate() throws {
        try super.validateForUpdate()
        
        try validateValues()
    }
}
