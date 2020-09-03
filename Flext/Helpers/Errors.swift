//
//  Errors.swift
//  Flext
//
//  Created by Michael Camilleri on 12/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

/**
 Represents an error in Flext.

 Swift does not provide a default error type. Instead, a type that implements
 the `Error` protocol needs to be specified. This struct defines a series of
 error states that are used throughout the app.
 */
struct FlextError: Error {

    // MARK: - ErrorType Enum

    /**
     Represents the error states used in Flext.
     */
    enum ErrorType {
        case unknown
        case failedToLoadPath
        case failedToReadFile
        case failedToCopyFile
        case failedToDeleteFile
        case failedToLoadJSContext
        case failedToEvaluateJavaScript
        case failedToFindProcessFunction
    }

    // MARK: - Properties

    /// The type of the error.
    var type: ErrorType

    /// The location where the error occurred.
    ///
    /// The location is a tuple that consists of a `String` representing the
    /// file and an `Int` representing the line number.
    var location: (String, Int)?

    // A log message to display.
    var logMessage: String {
        "Error type: \(self.type)" + format(location: self.location)
    }

    // MARK: - Initialisers

    /**
     Creates an error of the specified type and at the optional location.

     - Parameters:
        - type: The type of the error.
        - location: The location (source file and line number) of the error.
     */
    init(type: ErrorType, location: (String, Int)? = nil) {
        self.type = type
        self.location = location
    }

    // MARK: - Location Adding

    /**
     Returns a copy of the error with the location set.

     - Parameters:
        - location: The location (source file and line number) of the error.

     - Returns: A copy of the `FlextError` instance.
     */
    func with(location: (String, Int)) -> FlextError {
        var result = self
        result.location = location
        return result
    }

    // MARK: - Location Formatting

    /**
     Returns the formatted location.

     - Parameters:
        - location: The location (source file and line number) of the error.

     - Returns: The formatted string.
     */
    private func format(location: (String, Int)?) -> String {
        return location == nil ? "" : " in \(location!.0) at \(location!.1)"
    }
}

extension FlextError: LocalizedError {
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
        case .failedToDeleteFile:
            return "The selected file could not be deleted."
        case .failedToLoadJSContext:
            return "The JavaScript engine could not be loaded."
        case .failedToEvaluateJavaScript:
            return "The JavaScript in the selected file could not be evaluated."
        case .failedToFindProcessFunction:
            return "The process function could not be found in the selected file."
        }
    }
}
