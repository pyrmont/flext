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
    var isSelected: Bool
    var order: Int?
    var options: [String: String]
    
    init(for processor: Processor, isSelected: Bool = false) {
        self.name = processor.name
        self.isEnabled = processor.isEnabled
        self.isSelected = isSelected
        self.order = nil
        self.options = [:]
    }
    
    mutating func update(option: String, value: String) {
        options[option] = value
    }
}

struct Preferences: Codable {
    var processors: [String: ProcessorPreferences] = [:]

    mutating func save(_ processorModel: Processor, isSelected: Bool) {
        var processorPreferences = ProcessorPreferences(for: processorModel, isSelected: isSelected)
        
        for option in processorModel.options {
            guard let value = option.value else { continue }
            processorPreferences.update(option: option.name, value: value)
        }
        
        processors[processorModel.filename] = processorPreferences
    }
    
    mutating func save(_ processorModels: [Processor], ordering: [Processor], selected: Processor?) {
        for processorModel in processorModels {
            save(processorModel, isSelected: processorModel == selected)
        }
        
        for (index, processorModel) in ordering.enumerated() {
            processors[processorModel.filename]?.order = index
        }
    }
}

struct PreferencesManager {
    static var processors: [String: ProcessorPreferences] = preferences.processors
    static var appDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.inqk.Telekinesis")
    
    private static var preferenceFilename = "user_prefs.plist"
    private static var encoder = PropertyListEncoder()
    private static var decoder = PropertyListDecoder()
    
    private static var preferences = load()
    
    static func load() -> Preferences {
        guard let appDirectory = PreferencesManager.appDirectory else {
            NSLog("There was an error reading the application directory")
            return Preferences()
        }
        
        let preferencesFile = appDirectory.appendingPathComponent(preferenceFilename)
        guard FileManager.default.fileExists(atPath: preferencesFile.path) else {
            NSLog("The preferences file does not exist")
            return Preferences()
        }
        
        guard let data = try? Data.init(contentsOf: preferencesFile) else {
            NSLog("There was an error reading the data from the preferences file")
            return Preferences()
        }
        
        guard let preferences = try? decoder.decode(Preferences.self, from: data) else {
            NSLog("There was an error decoding the data from the preferences file")
            return Preferences()
        }
        
        return preferences
    }
    
    static func save(_ processorModels: [Processor], ordering: [Processor], selected: Processor?) {
        var newPreferences = Preferences()
        newPreferences.save(processorModels, ordering: ordering, selected: selected)
        
        guard let appDirectory = PreferencesManager.appDirectory else {
            NSLog("There was an error reading the application directory")
            return
        }

        guard let data = try? encoder.encode(newPreferences) else {
            NSLog("The preferences could not be converted to data")
            return
        }
        
        let preferencesFile = appDirectory.appendingPathComponent(preferenceFilename)
        do {
            try data.write(to: preferencesFile)
            preferences = newPreferences
        } catch {
            NSLog("Could not write the preferences file")
        }
    }
}

