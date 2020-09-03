//
//  Preferences.swift
//  Flext
//
//  Created by Michael Camilleri on 31/8/20.
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

    /// The status of whether the processor is favourited.
    var isFavourited: Bool

    /// The position of the processor in the list of enabled processors.
    var order: Int?

    /// The user-set options associated with the processor.
    var options: [String: String]

    // MARK: - Initialisers

    /**
     Creates preferences for a processor.

     - Parameters:
        - processor: The processor with which the preferences are associated.
     */
    init(for processor: Processor) {
        self.name = processor.name
        self.isEnabled = processor.isEnabled
        self.isFavourited = processor.isFavourited
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

    var selectedPath: IndexPath? = nil

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
     */
    mutating func save(_ processorModel: Processor) {
        var processorPreferences = ProcessorPreferences(for: processorModel)

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
        - selected: The selected processor.
     */
    mutating func save(_ processorModels: [Processor], ordering: [Processor], selectedPath: IndexPath?) {
        for processorModel in processorModels {
            save(processorModel)
        }

        for (index, processorModel) in ordering.enumerated() {
            processors[processorModel.filename]?.order = index
        }

        self.selectedPath = selectedPath
    }
}
