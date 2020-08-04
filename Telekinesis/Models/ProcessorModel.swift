//
//  ProcessorModel.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

struct ProcessorModel {
    enum InitError: Error {
        case invalidPath
    }
    
    var path: URL
    var hasOptions: Bool = false
    
    var filename: String { get { path.lastPathComponent } }
    var basename: String { get { filename.replacingOccurrences(of: ".js", with: "") } }
    var name: String { get { basename.replacingOccurrences(of: "-", with: " ") } }
    
    init(path: URL) throws {
        self.path = path
        self.hasOptions = try checkForOptions()
    }
    
    private func checkForOptions() throws -> Bool {
        guard let reader = LineReader(at: path) else { throw InitError.invalidPath }
        
        while let line = reader.nextLine {
            if !line.starts(with: "var process = function") { continue }
            return !line.starts(with: "var process = function(text)")
        }
        
        return false
    }
    
    static func findAll() -> [ProcessorModel] {
        guard let processorFileURLs = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "Processors") else { return [] }
        
        return processorFileURLs
            .map { try! ProcessorModel(path: $0)}
            .sorted(by: { $0.name < $1.name })
    }
}
