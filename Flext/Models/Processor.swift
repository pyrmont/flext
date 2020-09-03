//
//  Processor.swift
//  Flext
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation
import JavaScriptCore

// MARK: - ProcessorOption Class

/**
 Represents a processor option.
 */
class ProcessorOption {

    // MARK: - Properties

    /// The name of the processor option.
    var name: String

    /// The user-defined value of the processor option.
    ///
    /// The value is saved as a string but will be evaluated in the JavaScript
    /// context of the processor to return the appropriate JavaScript value.
    var value: String?

    /// The default value of the processor option.
    ///
    /// The value is saved as a string but will be evaluated in the JavaScript
    /// context of the processor to return the appropriate JavaScript value.
    var defaultValue: String?

    /// A comment associated with the processor option.
    var comment: String?

    // MARK: - Initialisers

    /**
     Creates a processor option.

     - Parameters:
        - name: The name of the option.
        - defaultValue: The default value for the option.
        - comment: The comment for the option.
     */
    init(name: String, defaultValue: String?, comment: String?) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)

        self.value = nil

        if defaultValue == nil || defaultValue!.isEmpty {
            self.defaultValue = nil
        } else {
            self.defaultValue = defaultValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if comment == nil || comment!.isEmpty {
            self.comment = nil
        } else {
            self.comment = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

extension Array where Element == ProcessorOption {

    // MARK: - Option Addition

    /**
     Appends an option to an array of processor options.

     - Parameters:
        - name: The name of the option.
        - defaultValue: The default value for the option.
        - comment: The comment for the option.
     */
    mutating func appendOption(name: String, defaultValue: String, comment: String) {
        guard name != "text" else { return }
        append(ProcessorOption(name: name, defaultValue: defaultValue, comment: comment))
    }
}

// MARK: - Processor Definition

/**
 Represents a processor.

 For performance reasons, the `Processor` class makes use of lazy properties for
 the `function` and `options` properties.
 */
class Processor {

    // MARK: - ProcessorType Enum

    /**
     Represents the type of processor.
     */
    enum ProcessorType: Int {
        case builtIn
        case userAdded
    }

    // MARK: - Properties

    /// The URL for the file associated with the processor.
    var path: URL

    /// The state of whether the processor has options.
    var hasOptions: Bool = false

    /// The state of whether the process is enabled.
    var isEnabled: Bool = true

    /// The state of whether the processor is favourited.
    var isFavourited: Bool = false

    /// The type of processor.
    var type: ProcessorType = .builtIn

    /// The external name of the processor.
    ///
    /// The external name of the processor is the name set by the user for a
    /// user-added processor.
    private var externalName: String?

    /// The lazily evaluated JavaScript function.
    lazy var function: JSValue? = {
        guard let jsContext = JSContext() else { return nil }

        do {
            let jsSourceContents = try String(contentsOf: path)
            jsContext.evaluateScript(jsSourceContents)
            return jsContext.objectForKeyedSubscript("process")
        } catch {
            NSLog(error.localizedDescription)
        }

        return nil
    }()

    /// The lazily evaluated options.
    lazy var options: [ProcessorOption] = {
        guard hasOptions else { return [] }

        var result = parseOptions()

        for (index, option) in result.enumerated() {
            guard let savedValue = PreferencesManager.processors[filename]?.options[option.name] else { continue }
            result[index].value = savedValue
        }

        return result
    }()

    /// The filename of the file associated with the processor.
    var filename: String { get { path.lastPathComponent } }

    /// The basename of the file associated with the processor.
    var basename: String { get { filename.replacingOccurrences(of: ".js", with: "") } }

    /// The name of the processor.
    var name: String {
        get {
            guard externalName == nil else { return externalName! }

            if let savedName = PreferencesManager.processors[filename]?.name {
                externalName = savedName
            } else {
                externalName = basename.replacingOccurrences(of: "-", with: " ")
            }

            return externalName!
        }
        set {
            externalName = newValue
        }
    }

    // MARK: - Initialisers

    /**
     Creates a processor.

     - Parameters:
        - path: The URL to the file associated with the processor.

     - Throws: The file cannot be checked for the existence of options.
     */
    init(path: URL) throws {
        self.path = path
        self.isEnabled = PreferencesManager.processors[filename]?.isEnabled ?? true
        self.isFavourited = PreferencesManager.processors[filename]?.isFavourited ?? false
        self.hasOptions = try checkForOptions()
    }

    /**
     Creates a processor of a particular type.

     - Parameters:
        - path: The URL to the file associated with the processor.
        - type: The type of the processor.

     - Throws: The file cannot be checked for the existence of options.
     */
    convenience init(path: URL, type: ProcessorType) throws {
        try self.init(path: path)
        self.type = type
    }

    /**
     Creates a processor of a particular type with a name.

     - Parameters:
        - path: The URL to the file associated with the processor.
        - type: The type of the processor.
        - name: The name of the processor.

     - Throws: The file cannot be checked for the existence of options.
     */
    convenience init(path: URL, type: ProcessorType, name: String) throws {
        try self.init(path: path, type: type)
        self.externalName = name
    }

    // MARK: - Option Parsing

    /**
     Checks whether the processor has options.

     This method checks whether the `process()` function takes any additional
     parameters. For performance reasons, this check does not actually evaluate
     the function. Instead it looks at each line of the JavaScript file and if
     the file contains a line that suggests the function contains additional
     arguments, it returns `true`. Otherwise, it returns `false`.

     - Throws: The line reader is unable to load the JavaScript file.

     - Returns: Whether the processor has options.
     */
    private func checkForOptions() throws -> Bool {
        guard let reader = LineReader(at: path) else { throw FlextError(type: .failedToLoadPath, location: (#file, #line)) }

        while let line = reader.nextLine {
            if line.starts(with: "var process = function(text,") {
                return true
            } else if line.starts(with: "var process = function(text)") {
                return false
            }
        }

        return false
    }

    /**
     Parses the options in the `process()` function definition.

     Flext supports processors with options. Options are additional arguments
     in the `process()` function definition. This method extracts those
     additional arguments.

     Unfortunately, JavaScript does not provide sophisticated reflection
     functions so we have to convert the function definition to a string and
     then manually parse out the arguments. This method supports parsing
     argument names, default values and comments immediately following argument.

     - Returns: An array of processor options.
     */
    private func parseOptions() -> [ProcessorOption] {
        let functionDefinition = function?.toString()

        var isComplete = false

        var beforeParams = true

        var inString = false
        var stringDelim = Character("\"")
        var isEscaped = false

        var isSingleComment = false
        var maybeSingleComment = false

        var inBlockComment = false
        var maybeBlockComment = false

        var expressionLevel = 0

        var params: [ProcessorOption] = []
        var paramName = ""
        var defaultValue = ""
        var comment = ""

        for char in functionDefinition! {
            guard !isComplete else { break }

            if inString {
                switch char {
                case "\"", "'":
                    defaultValue.append(char)

                    if isEscaped {
                        isEscaped = false
                    } else if char == stringDelim {
                        inString = false
                    }
                case "\\":
                    defaultValue.append(char)
                    isEscaped = true
                default:
                    defaultValue.append(char)
                    isEscaped = false
                }
                continue
            }

            if isSingleComment {
                if char == "\n" {
                    isSingleComment = false
                }
                continue
            }

            if inBlockComment {
                if !beforeParams {
                    comment.append(char)
                }
                if char == "*" {
                    maybeBlockComment = true
                } else if char == "/" {
                    if maybeBlockComment {
                        comment = String(comment.dropLast(2))
                        inBlockComment = false
                        maybeBlockComment = false
                    }
                }
                continue
            }

            if char == "/" {
                if maybeSingleComment {
                    isSingleComment = true
                    maybeSingleComment = false
                    maybeBlockComment = false
                } else {
                    maybeSingleComment = true
                    maybeBlockComment = true
                }
                continue
            }

            if char == "*" {
                if maybeBlockComment {
                    inBlockComment = true
                    maybeSingleComment = false
                    maybeBlockComment = false
                    continue
                }
            }

            if maybeSingleComment || maybeBlockComment {
                maybeSingleComment = false
                maybeBlockComment = false

                if expressionLevel > 0 {
                    defaultValue.append("/")
                }
            }

            if beforeParams {
                if char == "(" {
                    beforeParams = false
                }
                continue
            }

            if expressionLevel > 0 {
                switch char {
                case "\"", "'":
                    defaultValue.append(char)
                    inString = true
                    stringDelim = char
                case "(":
                    expressionLevel += 1
                case ")":
                    if expressionLevel == 1 {
                        params.appendOption(name: paramName, defaultValue: defaultValue, comment: comment)
                        isComplete = true
                    } else {
                        defaultValue.append(char)
                        expressionLevel -= 1
                    }
                case ",":
                    if expressionLevel == 1 {
                        params.appendOption(name: paramName, defaultValue: defaultValue, comment: comment)
                        paramName = ""
                        defaultValue = ""
                        comment = ""
                        expressionLevel = 0
                    } else {
                        defaultValue.append(char)
                    }
                default:
                    defaultValue.append(char)
                }
                continue
            }

            switch char {
            case ")":
                params.appendOption(name: paramName, defaultValue: defaultValue, comment: comment)
                isComplete = true
            case "=":
                expressionLevel += 1
            case ",":
                params.appendOption(name: paramName, defaultValue: defaultValue, comment: comment)
                paramName = ""
                defaultValue = ""
                comment = ""
                expressionLevel = 0
            case " ":
                break
            default:
                paramName.append(char)
            }
        }

        return params
    }
}

// MARK: - Processor Factory

extension Processor {
    /**
     Returns all the processors in Flext.

     - Returns: An array of all the processors in the app. This comprises both
                built-in and user-added processors.
     */
    static var all: [Processor] {
        guard let builtInProcessorURLs = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "Processors") else { return [] }

        var userAddedProcessorURLs: [URL] = []
        do {
            guard let appDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.inqk.Flext") else { throw FlextError(type: .failedToLoadPath )}
            let fileURLs = FileManager.default.enumerator(at: appDirectory, includingPropertiesForKeys: nil)!
            for case let fileURL as URL in fileURLs where fileURL.pathExtension == "js" {
                userAddedProcessorURLs.append(fileURL)
            }
        } catch {
            NSLog("There was an error accessing the documents directory")
        }

        let builtInProcessors = builtInProcessorURLs
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            .map { try! Processor(path: $0)}

        let userAddedProcessors = userAddedProcessorURLs
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            .map { try! Processor(path: $0, type: .userAdded)}

        return builtInProcessors + userAddedProcessors
    }
}

extension Processor: Equatable {

    // MARK: - Processor Equivalence

    /**
     Returns whether the processors are equal.

     Two processors are considered to be equal if the files associated with the
     processors are located in the same place.

     This means that two processors might represent identical JavaScript
     functions but if they are stored in different locations, they are treated
     as different processors. This is intentional as it permits a user to add
     multiple copies of the same processor.

     - Parameters:
        - lhs: The first processor to compare.
        - rhs: The second processor to compare.

     - Returns: Whether the two processors are equal.
     */
    static func == (lhs: Processor, rhs: Processor) -> Bool {
        lhs.path == rhs.path
    }
}

extension Array where Element == Processor {

    // MARK: - Processor Retrieval

    /**
     Returns the processor (if one exists) for a URL

     This method returns the first processor in the array that matches the
     `path`. There is no guarantee that there is only one such processor in the
     array.

     - Parameters:
        - path: The URL of the file associated with a processor.

     - Returns: The processor associated with the file.
     */

    func find(path: URL) -> Processor? {
        first(where: { $0.path == path })
    }

    /**
     Returns safely the processor for an index

     Swift does no bounds checking when looking up an index in an array. This
     method returns `nil` if `index` is less than or greater than the indices
     accessible in the array.

     - Parameters:
        - index: The index to check.

     - Returns: The processor if one exists at the `index`.
     */
    func at(_ index: Index) -> Processor? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
