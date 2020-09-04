//
//  PreferencesManager.swift
//  Flext
//
//  Created by Michael Camilleri on 6/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

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
    static func save(_ processorModels: [Processor], ordering: ProcessorOrdering, selectedPath: IndexPath?) {
        var newPreferences = Preferences()
        newPreferences.save(processorModels, ordering: ordering, selectedPath: selectedPath)

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

