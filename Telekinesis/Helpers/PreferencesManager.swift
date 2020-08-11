//
//  PreferencesManager.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 6/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

struct ProcessorPreference: Codable {
    var isEnabled: Bool = true
    var options: [String: String]
}

struct Preferences: Codable {
    var processors: [URL: ProcessorPreference] = [:]
}

struct PreferencesManager {
    enum PreferenceType {
        case processors
    }
    
    static var encoder = PropertyListEncoder()
    static var decoder = PropertyListDecoder()
    
    static var processors: [URL: ProcessorPreference] = {
        return preferences.processors
    }()
    
    private static var preferences: Preferences = {
        guard let appSupportDirectory = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            print("There was an error reading the application support directory.")
            return Preferences()
        }
        
        let preferencesFile = appSupportDirectory.appendingPathComponent("user_prefs.plist")
        guard FileManager.default.fileExists(atPath: preferencesFile.path) else {
            print("The preferences file does not exist.")
            return Preferences()
        }
        
        guard let data = try? Data.init(contentsOf: preferencesFile) else {
            print("There was an error reading the data from the preferences file (possibly it does not exist).")
            return Preferences()
        }
        
        guard let preferences = try? decoder.decode(Preferences.self, from: data) else {
            print("There was an error decoding the data from the preferences file.")
            return Preferences()
        }
        
        return preferences
    }()
    
    static func saveProcessorOptions(_ options: [ProcessorOption], for url: URL) {
        for option in options {
            if var processor = processors[url] {
                processor.options[option.name] = option.value
            } else {
                guard let value = option.value else { continue }
                processors[url] = ProcessorPreference(options: [option.name: value])
            }
        }
    }
}

