//
//  Processor.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation
import JavaScriptCore

// MARK: - ProcessorOption Definition

class ProcessorOption {
    var name: String
    var value: String?
    var defaultValue: String?
    var comment: String?
    
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
    mutating func appendOption(name: String, defaultValue: String, comment: String) {
        guard name != "text" else { return }
        append(ProcessorOption(name: name, defaultValue: defaultValue, comment: comment))
    }
}

// MARK: - Processor Definition

class Processor {
    enum ProcessorType: Int {
        case builtIn
        case userAdded
    }
    
    // MARK: - Public Properties
    
    var path: URL
    var hasOptions: Bool = false
    var isEnabled: Bool = true
    var type: ProcessorType = .builtIn
    
    // MARK: - Private Properties
    
    private var externalName: String?
    
    // MARK: - Lazy Properties
    
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
    
    lazy var options: [ProcessorOption] = {
        guard hasOptions else { return [] }
        
        var result = parseOptions()
        
        for (index, option) in result.enumerated() {
            guard let savedValue = PreferencesManager.processors[filename]?.options[option.name] else { continue }
            result[index].value = savedValue
        }
        
        return result
    }()
    
    // MARK: - Computed Properties
    
    var filename: String { get { path.lastPathComponent } }
    var basename: String { get { filename.replacingOccurrences(of: ".js", with: "") } }
    
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

    // MARK: - Initialiser
    
    init(path: URL) throws {
        self.path = path
        self.isEnabled = PreferencesManager.processors[filename]?.isEnabled ?? true
        self.hasOptions = try checkForOptions()
    }
    
    convenience init(path: URL, type: ProcessorType) throws {
        try self.init(path: path)
        self.type = type
    }
    
    convenience init(path: URL, type: ProcessorType, name: String) throws {
        try self.init(path: path, type: type)
        self.externalName = name
    }
    
    // MARK: - Option Parsing

    private func checkForOptions() throws -> Bool {
        guard let reader = LineReader(at: path) else { throw TelekinesisError(type: .failedToLoadPath, location: (#file, #line)) }
        
        while let line = reader.nextLine {
            if !line.starts(with: "var process = function") { continue }
            return !line.starts(with: "var process = function(text)")
        }
        
        return false
    }
    
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
    static var all: [Processor] {
        guard let builtInProcessorURLs = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "Processors") else { return [] }

        var userAddedProcessorURLs: [URL] = []
        do {
            guard let appDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.inqk.Telekinesis") else { throw TelekinesisError(type: .failedToLoadPath )}
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

// MARK: - Extensions

extension Processor: Equatable {
    static func == (lhs: Processor, rhs: Processor) -> Bool {
        lhs.path == rhs.path
    }
}

extension Array where Element == Processor {
    func find(path: URL) -> Processor? {
        first(where: { $0.path == path })
    }
    
    func at(_ index: Index) -> Processor? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
