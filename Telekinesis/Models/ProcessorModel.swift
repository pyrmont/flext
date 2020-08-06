//
//  ProcessorModel.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation
import JavaScriptCore

struct ProcessorOption {
    var name: String
    var defaultValue: String?
    var comment: String?
    
    init(name: String, defaultValue: String?, comment: String?) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
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

struct ProcessorModel {
    enum ProcessorError: Error {
        case invalidPath
    }
    
    var path: URL
    var hasOptions: Bool = false
    
    // MARK: - Computed Properties
    
    var filename: String { get { path.lastPathComponent } }
    var basename: String { get { filename.replacingOccurrences(of: ".js", with: "") } }
    var name: String { get { basename.replacingOccurrences(of: "-", with: " ") } }

    var function: JSValue? {
        get {
            guard let jsContext = JSContext() else { return nil }
            
            do {
                let jsSourceContents = try String(contentsOf: path)
                jsContext.evaluateScript(jsSourceContents)
                return jsContext.objectForKeyedSubscript("process")
            } catch {
                print(error.localizedDescription)
            }
            
            return nil
        }
    }

    var options: [ProcessorOption] {
        get {
            guard hasOptions else { return [] }
            return parseOptions()
        }
    }
    
    // MARK: - Initialiser
    
    init(path: URL) throws {
        self.path = path
        self.hasOptions = try checkForOptions()
    }
    
    // MARK: - Options

    private func checkForOptions() throws -> Bool {
        guard let reader = LineReader(at: path) else { throw ProcessorError.invalidPath }
        
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
    
    // MARK: - Static Functions
    
    static func findAll() -> [ProcessorModel] {
        guard let processorFileURLs = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "Processors") else { return [] }
        
        return processorFileURLs
            .map { try! ProcessorModel(path: $0)}
            .sorted(by: { $0.name < $1.name })
    }
}

extension Array where Element == ProcessorOption {
    mutating func appendOption(name: String, defaultValue: String, comment: String) {
        guard name != "text" else { return }
        
        append(ProcessorOption(name: name, defaultValue: defaultValue, comment: comment))
    }
}
