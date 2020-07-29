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
}
