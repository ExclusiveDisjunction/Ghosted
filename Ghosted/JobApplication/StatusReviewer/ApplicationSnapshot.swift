//
//  ApplicationSnapshot.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import SwiftUI
import CoreData
import Observation
import os
import ExDisj

public struct StaticApplicationStatusSnapshot : Identifiable, Sendable, Equatable, Hashable {
    public init(id: NSManagedObjectID, position: String, company: String, current: JobApplicationState, lastUpdate: Date) {
        self.id = id;
        self.position = position;
        self.company = company;
        self.currentState = current;
        self.lastUpdated = lastUpdate;
    }
    
    public let id: NSManagedObjectID;
    public let currentState: JobApplicationState;
    public let position: String;
    public let company: String;
    public let lastUpdated: Date;
}


@Observable
public final class ApplicationStatusSnapshot : Identifiable, Sendable, @MainActor Hashable {
    @MainActor
    public init(from: StaticApplicationStatusSnapshot) {
        self.id = from.id;
        self.position = from.position;
        self.company = from.company;
        self.currentState = from.currentState;
        self.updateStateTo = from.currentState;
        self.lastUpdated = from.lastUpdated;
    }
    
    @ObservationIgnored public let id: NSManagedObjectID;
    @ObservationIgnored public let currentState: JobApplicationState;
    @ObservationIgnored public let position: String;
    @ObservationIgnored public let company: String;
    @ObservationIgnored public let lastUpdated: Date;
    @MainActor
    public var updateStateTo: JobApplicationState;
    /// Allows the user to indicate that they do not want to change the job status
    @MainActor
    public var updatedFlag: Bool = false;
    
    @MainActor
    public var didUpdate: Bool {
        updateStateTo != currentState || updatedFlag
    }
    
    @MainActor
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(currentState)
        hasher.combine(position)
        hasher.combine(company)
        hasher.combine(lastUpdated)
        hasher.combine(updateStateTo)
        hasher.combine(updatedFlag)
    }
    
    @MainActor
    public static func ==(lhs: ApplicationStatusSnapshot, rhs: ApplicationStatusSnapshot) -> Bool {
        lhs.id == rhs.id && lhs.currentState == rhs.currentState && lhs.position == rhs.position && lhs.company == rhs.company && lhs.lastUpdated == rhs.lastUpdated && lhs.updateStateTo == rhs.updateStateTo && lhs.updatedFlag == rhs.updatedFlag
    }
}
