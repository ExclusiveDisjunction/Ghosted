//
//  Warning.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

/// A simple basis for what warnings should include.
public protocol WarningBasis  {
    /// The encoded message that the warning presents.
    var message: String { get }
}

/// The warning message to be presented.
public enum SelectionWarningKind: Int, Identifiable, WarningBasis {
    
    /// The warning that no elements are selected, when at least one was expected.
    case noneSelected = 0
    /// The warning that too many elements are selected, as only one was expected.
    case tooMany = 1
    
    public var id: Self { self }
    /// Returns the `LocalizedStringKey` that
    public var message: String {
        switch self {
            case .noneSelected: NSLocalizedString("noItems", comment: "")
            case .tooMany:      NSLocalizedString("tooManyItems", comment: "")
        }
    }
}

/// A string-based message used to indicate errors for the UI.
public struct StringWarning: Identifiable, WarningBasis {
    public init(_ message: String, id: UUID = UUID()) {
        self.message = message
        self.id = id
    }
    public let message: String
    
    public var id: UUID;
}

public struct InternalErrorWarning : WarningBasis {
    public var message: String { NSLocalizedString("internalError", comment: "") }
}

/// An observable class that provides warning funcntionality. It includes a memeber, `isPresented`, which can be bound. This value will become `true` when the internal `warning` is not `nil`.
@Observable
public class WarningManifest<T> where T: WarningBasis {
    public init() {
        warning = nil;
    }
    
    public var warning: T?;
    public var message: String? { warning?.message }
    public var isPresented: Bool {
        get { warning != nil }
        set {
            if self.isPresented == newValue { return }
            
            warning = nil
        }
    }
}

/// A specalized version of `BaseWarningManifest<T>` that works for `WarningKind` values.
public typealias SelectionWarningManifest = WarningManifest<SelectionWarningKind>;
/// A specalized version of `BaseWarningManifest<T>` that works for `WarningMessage` values.
public typealias StringWarningManifest = WarningManifest<StringWarning>
public typealias ValidationWarningManifest = WarningManifest<ValidationFailure>;
public typealias InternalWarningManifest = WarningManifest<InternalErrorWarning>;

public struct WarningManifestExtension<T> : ViewModifier where T: WarningBasis {
    public init(from: WarningManifest<T>) {
        self.from = from;
    }
    
    @Bindable private var from: WarningManifest<T>;
    
    public func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $from.isPresented) {
                Button("Ok") {
                    from.isPresented = false
                }
            } message: {
                Text(verbatim: from.warning?.message ?? NSLocalizedString("internalError", comment: ""))
            }
    }
}

extension View {
    public func withWarning<T>(_ manifest: WarningManifest<T>) -> some View
    where T: WarningBasis {
        self.modifier(WarningManifestExtension(from: manifest))
    }
}
