//
//  Errors.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 12/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

struct TelekinesisError: Error {
    enum ErrorType {
        case unknown
        case failedToLoadPath
        case failedToReadFile
        case failedToCopyFile
        case failedToLoadJSContext
        case failedToEvaluateJavaScript
        case failedToFindProcessFunction
    }

    var type: ErrorType
    var location: (String, Int)?
    var message: String?
    
    var logMessage: String {
        "Error type: \(self.type)" + format(location: self.location)
    }
    
    init(type: ErrorType, location: (String, Int)? = nil) {
        self.type = type
        self.location = location
    }
    
    func with(location: (String, Int)) -> TelekinesisError {
        var result = self
        result.location = location
        return result
    }
    
    private func format(location: (String, Int)?) -> String {
        return location == nil ? "" : " in \(location!.0) at \(location!.1)"
    }
}

extension TelekinesisError: LocalizedError {
    var errorDescription: String? {
        switch self.type {
        case .unknown:
            return "The operation failed for an unknown reason."
        case .failedToLoadPath:
            return "The selected path could not be opened."
        case .failedToReadFile:
            return "The selected file could not be read."
        case .failedToCopyFile:
            return "The selected file could not be copied."
        case .failedToLoadJSContext:
            return "The JavaScript engine could not be loaded."
        case .failedToEvaluateJavaScript:
            return "The JavaScript in the selected file could not be evaluated."
        case .failedToFindProcessFunction:
            return "The process function could not be found in the selected file."
        }
    }
}
