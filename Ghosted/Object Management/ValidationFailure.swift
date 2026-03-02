//
//  ValidationFailure.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI

/// A failure to validate a value out of a snapshot/element.
public enum ValidationFailureReason: Int, Identifiable, Sendable, Error {
    /// A uniqueness check failed over a set of identifiers.
    case unique
    /// A field was empty
    case empty
    /// A field was negative
    case negativeAmount
    /// A field is too large
    case tooLargeAmount
    /// A field is too small
    case tooSmallAmount
    /// A field has invalid input
    case invalidInput
    ///Happens when there is an internal expection that failed
    case internalError
    
    public var id: Self { self }
    
    public var localizedDescription: String {
        switch self {
            case .unique:         "The current element is not unique."
            case .empty:          "Please ensure all fields are filled in."
            case .negativeAmount: "Please ensure all amount values are positive."
            case .tooLargeAmount: "Please ensure all fields are not too large. (Ex: Percents greater than 100%)"
            case .tooSmallAmount: "Please ensure all fields are not too small."
            case .invalidInput:   "One or more fields has invalid input."
            case .internalError:  "Internal error failure"
        }
    }
}

public struct ValidationFailureBuilder : Sendable, ~Copyable {
    public init() {
        self.grievences = [:];
    }
    
    public var grievences: [String : ValidationFailureReason];
    
    public mutating func add(prop: String, reason: ValidationFailureReason) {
        self.grievences[prop] = reason;
    }
    
    public consuming func build() -> ValidationFailure? {
        if self.grievences.isEmpty {
            return nil;
        } else {
            return ValidationFailure(self.grievences);
        }
    }
}

public struct ValidationFailure : Sendable, Error, WarningBasis {
    public init(_ grievences: [String : ValidationFailureReason]) {
        self.grievences = grievences;
        self.message = Self.buildMessage(grievences);
    }
    
    private static func buildMessage(_ grievences: [String: ValidationFailureReason]) -> String {
        let header = NSLocalizedString("Please fix the following issues:\n", comment: "Validation Failure Header");
        
        var lines: [String] = [];
        let bundle = Bundle.main;
        for (prop, reason) in grievences {
            let propName = bundle.localizedString(forKey: prop, value: nil, table: nil);
            let fragment = switch reason {
                case .empty: "cannot be empty"
                case .invalidInput: "is invalid"
                case .negativeAmount: "cannot be negative"
                case .tooLargeAmount: "is too large"
                case .tooSmallAmount: "is too small"
                case .unique: "must be unique"
                case .internalError: "had an internal error"
            };
            
            let fragTrans = bundle.localizedString(forKey: fragment, value: nil, table: nil);
            let line = "\"\(propName)\" \(fragTrans)";
            lines.append(line)
        }
        
        let joinedLines = lines.joined(separator: "\n");
        
        return header + joinedLines;
    }
    
    public let grievences: [String: ValidationFailureReason];
    public let message: String;
}

extension ValidationFailureReason : Displayable {
     public var display: LocalizedStringKey {
        switch self {
            case .unique:         "The current element is not unique."
            case .empty:          "Please ensure all fields are filled in."
            case .negativeAmount: "Please ensure all amount values are positive."
            case .tooLargeAmount: "Please ensure all fields are not too large. (Ex: Percents greater than 100%)"
            case .tooSmallAmount: "Please ensure all fields are not too small."
            case .invalidInput:   "One or more fields has invalid input."
            case .internalError:
                fallthrough
            default:
                "internalError"
                
        }
    }
}
