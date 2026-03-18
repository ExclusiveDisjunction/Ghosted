//
//  AppliedCountEntry.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/17/26.
//

import Foundation

struct AppliedCountEntry : Sendable, Codable, Equatable, Hashable {
    let date: Date;
    let count: Int;
}


