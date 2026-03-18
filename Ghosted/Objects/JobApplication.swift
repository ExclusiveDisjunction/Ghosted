//
//  JobApplication.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData
import ExDisj
import Combine

/// The state of an application, specifically, which stage of the job application process the job is in.
public enum JobApplicationState : Int16, Equatable, Hashable, Codable, Sendable, CaseIterable, Identifiable, CustomStringConvertible {
    /// The application has been submitted.
    case applied = 0
    /// The application is being reviewed by the hiring team.
    case underReview = 1
    /// The applicant is being interviewed, or had an interview, with the hiring team.
    case inInterview = 2
    /// The applicant was rejected by the hiring team.
    case rejected = 3
    /// The application was accepted!
    case accepted = 4
    /// The application was ghosted.
    case ghosted = 5
    
    public var id: Self { self }
    
    /// The display color to use to indicate the status of the application on the UI.
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
    
    public var description: String {
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

/// The location where the job will take place. This is either physical or virtual, or both.
public enum JobLocation : Int16, Equatable, Hashable, Codable, Sendable, CaseIterable, Identifiable {
    /// The applicant is expected to be at the worksite.
    case onSite = 0
    /// The applicant is expected to be at the worksite on select workdays.
    case hybrid = 1
    /// The applicant does not visit the worksite.
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

/// The role type of the job application. This is how many hours, or consistency of hours.
public enum JobKind : Int16, Equatable, Hashable, Codable, Sendable, CaseIterable, Identifiable {
    /// The applicant works a full work week (40 hours in USA)
    case fullTime = 0
    /// The applicant works less than a full work week.
    case partTime = 1
    /// The applicant is a seasonal hire.
    case seasonal = 2
    /// The applicant is a contractor or freelanced to the company.
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
    /// The name of the position that was applied to.
    var position: String {
        get { self.internalPosition ?? String() }
        set { self.internalPosition = newValue }
    }
    /// The company offering the position.
    var company: String {
        get { self.internalCompany ?? String() }
        set { self.internalCompany = newValue }
    }
    /// The location of the worksite
    var location: String {
        get { self.internalLocation ?? String() }
        set { self.internalLocation = newValue }
    }
    /// What date the application was submitted
    var appliedOn: Date {
        get { self.internalAppliedOn ?? .distantPast }
        set { self.internalAppliedOn = newValue }
    }
    /// The status of the job application
    var state: JobApplicationState {
        get { JobApplicationState(rawValue: self.internalState) ?? .applied }
        set {
            self.objectWillChange.send()
            self.internalState = newValue.rawValue
        }
    }
    /// The kind of job the company is offering.
    var kind: JobKind {
        get { JobKind(rawValue: self.internalKind) ?? .fullTime }
        set {
            self.objectWillChange.send()
            self.internalKind = newValue.rawValue
        }
    }
    /// The kind of location expectations for the applicant.
    var locationKind: JobLocation {
        get { JobLocation(rawValue: self.internalLocationKind) ?? .onSite }
        set {
            self.objectWillChange.send()
            self.internalLocationKind = newValue.rawValue
        }
    }
    /// Any notes about the application or company.
    var notes: String {
        get { self.internalNotes ?? String() }
        set { self.internalNotes = newValue }
    }
    
    /// Determines if the internal state of the application is valid.
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
