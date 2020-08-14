//
//  PreferencesManager.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 6/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

struct ProcessorPreferences: Codable {
    var name: String
    var isEnabled: Bool
    var options: [String: String]
    
    init(for processor: ProcessorModel) {
        self.name = processor.name
        self.isEnabled = processor.isEnabled
        self.options = [:]
    }
}

struct Preferences: Codable {
    var processors: [URL: ProcessorPreferences] = [:]
}

struct PreferencesManager {
    enum PreferenceType {
        case processors
    }
    
    static var encoder = PropertyListEncoder()
    static var decoder = PropertyListDecoder()
    
    static var processors: [URL: ProcessorPreferences] = {
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
    
    static func save(_ processorModel: ProcessorModel) {
        var preferences = processors[processorModel.path] ?? ProcessorPreferences(for: processorModel)
        for option in processorModel.options {
            preferences.options[option.name] = option.value
        }
        processors[processorModel.path] = preferences
    }
}

