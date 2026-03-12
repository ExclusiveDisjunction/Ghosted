//
//  StatusEnvironment.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import SwiftUI

fileprivate struct StatusReviewerKey : EnvironmentKey {
    typealias Value = StatusReviewer?;
    
    static var defaultValue: StatusReviewer? { nil }
}
public extension EnvironmentValues {
    var statusReviewer: StatusReviewer? {
        get { self[StatusReviewerKey.self] }
        set { self[StatusReviewerKey.self] = newValue }
    }
}
