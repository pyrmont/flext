//
//  ProcessorModel.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

struct ProcessorModel {
    var path: URL
    
    var filename: String { get { path.lastPathComponent } }
    var basename: String { get { filename.replacingOccurrences(of: ".js", with: "") } }
    var name: String { get { basename.capitalized.replacingOccurrences(of: "-", with: " ") } }
    
    static func findAll() -> [ProcessorModel] {
        guard let processorFileURLs = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "Processors") else { return [] }
        
        return processorFileURLs
            .map { ProcessorModel(path: $0 )}
            .sorted(by: { $0.name < $1.name })
    }
}
