//
//  PreferencesManager.swift
//  Flext
//
//  Created by Michael Camilleri on 6/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

// MARK: - ProcessorPreferences Struct

/**
 Represents the preferences for a processor.
 */
struct ProcessorPreferences: Codable {
    
    // MARK: - Properties
    
    /// The name of the processor.
    var name: String
    
    /// The status of whether the processor is enabled.
    var isEnabled: Bool
    
    /// The status of whether the processor is the active processor.
    var isSelected: Bool
    
    /// The position of the processor in the list of enabled processors.
    var order: Int?
    
    /// The user-set options associated with the processor.
    var options: [String: String]
    
    // MARK: - Initialisers
    
    /**
     Creates preferences for a processor.
     
     - Parameters:
        - processor: The processor with which the preferences are associated.
        - isSelected: The state of whether the processor is the active
                      processor.
     */
    init(for processor: Processor, isSelected: Bool = false) {
        self.name = processor.name
        self.isEnabled = processor.isEnabled
        self.isSelected = isSelected
        self.order = nil
        self.options = [:]
    }
    
    // MARK: Option Updating
    
    /**
     Updates the value of an option.
     
     The value of all options are stored as strings which are evaluated before
     execution within the JavaScript context of the processor to determine the
     actual JavaScript value.
     
     - Parameters:
        - option: The key of the option to update.
        - value: The value to update.
     */
    mutating func update(option: String, value: String) {
        options[option] = value
    }
}

// MARK: - Preferences Struct

/**
 Represents a collection of `ProcessorPreferences` objects.
 */
struct Preferences: Codable {
    
    // MARK: - Properties
    
    /// The dictionary of processor preferences.
    ///
    /// The key used for each set of preferences is the URL to the processor.
    var processors: [String: ProcessorPreferences] = [:]

    // MARK: - Saving
    
    /**
     Saves the preferences for the processor.
     
     - Parameters:
        - processorModel: The processor with which the preferences are
                          associated.
        - isSelected: The state of whether the processor is the active processor
                      or not.
     */
    mutating func save(_ processorModel: Processor, isSelected: Bool) {
        var processorPreferences = ProcessorPreferences(for: processorModel, isSelected: isSelected)
        
        for option in processorModel.options {
            guard let value = option.value else { continue }
            processorPreferences.update(option: option.name, value: value)
        }
        
        processors[processorModel.filename] = processorPreferences
    }
    
    /**
     Saves the preferences for a set of processors in a given order.
     
     - Parameters:
        - processorModels: The processors with which the preferences are
                           associated.
        - ordering: The ordering of the processors.
        - selected: The active processor.
     */
    mutating func save(_ processorModels: [Processor], ordering: [Processor], selected: Processor?) {
        for processorModel in processorModels {
            save(processorModel, isSelected: processorModel == selected)
        }
        
        for (index, processorModel) in ordering.enumerated() {
            processors[processorModel.filename]?.order = index
        }
    }
}

// MARK: - PreferencesManager Struct

/**
 Represents a manager of preferences.
 
 Some people might call this a factory.
 */
struct PreferencesManager {
    
    // MARK: - Properties
    
    /// The preferences of the processors.
    static var processors: [String: ProcessorPreferences] = preferences.processors
    
    /// The application directory.
    static var appDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.inqk.Flext")
    
    /// The filename to use for the preferences file that is persisted on disk.
    private static var preferenceFilename = "user_prefs.plist"
    
    /// The property list encoder for the preferences.
    private static var encoder = PropertyListEncoder()
    
    /// The property list decoder for the preferences.
    private static var decoder = PropertyListDecoder()
    
    /// The preferences loaded from the file on disk.
    private static var preferences = load()
    
    // MARK: - File Loading
    
    /**
     Loads the preferences from disk.
     
     - Returns: The preferences that were persisted on disk (or a blank set of
                preferences if none have been saved).
     */
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
    
    // MARK: - File Saving
    
    /**
     Saves the preferences to disk.
     
     - Parameters:
        - processorModels: The collection of processors.
        - ordering: An ordering of the processors.
        - selected: The active processor.
     */
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

