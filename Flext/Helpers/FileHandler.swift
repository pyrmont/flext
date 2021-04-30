//
//  FileHandler.swift
//  Flext
//
//  Created by Michael Camilleri on 2/9/20.
//  Copyright © 2021 Michael Camilleri. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0.

import Foundation
import JavaScriptCore

struct FileHandler {
    /**
     Copies the file to the group directory.

     This method attempts to copy the file chosen by the user to the group
     directory for the `group.net.inqk.Flext` group (this is so the file will be
     available to the action extension). Before adding the file, this method
     evaluates the script to check that the `process()` function is defined and
     that it takes at least one argument.

     - Parameters:
        - url: The URL of the file to be copied.

     - Throws: The file could not be copied to the group directory.

     - Returns: The URL of the copy of the file.
     */
    static func addFile(at url: URL) throws -> URL? {
        var importURL: URL? = nil
        var importError: FlextError? = nil

        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, options: [.withoutChanges], error: &error) { (url) in
            do {
                guard let jsContext = JSContext() else { throw FlextError(type: .failedToLoadJSContext) }
                guard let jsSource = try? String(contentsOf: url) else { throw FlextError(type: .failedToReadFile) }
                jsContext.evaluateScript(jsSource)
                guard let parameterNumber = jsContext.evaluateScript("process.length") else { throw FlextError(type: .failedToEvaluateJavaScript) }
                guard parameterNumber.isNumber && parameterNumber.toInt32() > 0 else { throw FlextError(type: .failedToFindProcessFunction) }
                guard let appDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.inqk.Flext") else { throw FlextError(type: .failedToLoadPath) }

                importURL = URL(fileURLWithPath: UUID().uuidString + "." + url.pathExtension, isDirectory: false, relativeTo: appDirectory)
                try FileManager.default.copyItem(at: url, to: importURL!)
            } catch let error as FlextError {
                importError = error.with(location: (#file, #line))
            } catch let error as NSError where error.code == NSFileWriteFileExistsError {
                importError = FlextError(type: .failedToCopyFile, location: (#file, #line))
            } catch {
                importError = FlextError(type: .unknown, location: (#file, #line))
            }
        }

        guard importError == nil else { throw importError! }

        return importURL
    }

    // MARK: - Removing Files

    /**
     Deletes the file from the group directory.

     This method attempts to delete the file chosen by the user from the group
     directory for the `group.net.inqk.Flext` group.

     - Parameters:
        - url: The URL of the file to be deleted.

     - Throws: The file could not be deleted from the group directory.
     */
    static func removeFile(at url: URL) throws {
        var deleteError: FlextError? = nil

        var error: NSError? = nil
        NSFileCoordinator().coordinate(writingItemAt: url, options: [.forDeleting], error: &error) { (url) in
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError where error.code == NSFileWriteFileExistsError {
                deleteError = FlextError(type: .failedToDeleteFile, location: (#file, #line))
            } catch {
                deleteError = FlextError(type: .unknown, location: (#file, #line))
            }
        }

        guard deleteError == nil else { throw deleteError! }
    }
}
