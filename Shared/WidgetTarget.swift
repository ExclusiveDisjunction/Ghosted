//
//  WidgetTarget.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/17/26.
//

import Foundation

public let containerName = "group.com.exdisj.Ghosted.WidgetStore";

public enum WidgetTarget : Sendable, Codable, Equatable, Hashable, CaseIterable {
    case appliedCounts;
    
    public var fileName: String {
        switch self {
            case .appliedCounts: "appliedCounts.json"
        }
    }
}

public enum WidgetLoadError : Error {
    case noSuchFile
    case fileLoad(any Error)
    case decode(any Error)
}

public func getFileContents<T>(fileManager: FileManager = .default, forWidget: WidgetTarget) throws(WidgetLoadError) -> T? where T: Decodable {
    guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: containerName) else {
        throw .noSuchFile
    }
    
    let fileUrl = url.appending(component: forWidget.fileName);
    guard fileUrl.isFileURL && fileManager.fileExists(atPath: fileUrl.path()) else {
        return nil;
    }
    
    let contents: Data;
    do {
        contents = try Data(contentsOf: fileUrl);
    }
    catch let e {
        throw .fileLoad(e)
    }
    
    do {
        return try JSONDecoder().decode(T.self, from: contents);
    }
    catch let e {
        throw .decode(e)
    }
}
public func saveFileContents<T>(data: T, fileManager: FileManager = .default, forWidget: WidgetTarget) throws(WidgetLoadError) where T: Encodable {
    guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: containerName) else {
        throw .noSuchFile
    }
    
    let fileUrl = url.appending(component: forWidget.fileName);
    
    let toWrite: Data;
    do {
        toWrite = try JSONEncoder().encode(data);
    }
    catch let e {
        throw .decode(e)
    }
    
    guard fileManager.createFile(atPath: fileUrl.path(), contents: toWrite) else {
        throw .noSuchFile
    }
}
