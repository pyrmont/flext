//
//  SettingsManager.swift
//  Flext
//
//  Created by Michael Camilleri on 15/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

// MARK: - SettingValue Protocol

/**
 Represents a setting value.
 
 Swift does not provide a union type. This protocol essentially functions as a
 way to achieve a similar effect.
 */
protocol SettingValue { }

extension Array: SettingValue where Element == Setting {}
extension String: SettingValue {}
extension Webpage: SettingValue {}

// MARK: - SettingItem Protocol

/**
 Represents a setting item.
 */
protocol SettingItem {

    // MARK: - Properties
    
    /// The name of the item.
    var name: String { get }
    
    /// The type of the setting.
    var settingType: Setting.SettingType { get }
}

extension Processor: SettingItem {
    var settingType: Setting.SettingType { .processor }
}

extension Setting: SettingItem {
    var settingType: Setting.SettingType { self.type }
}

// MARK: - Setting Class

/**
 Represents a setting.
 
 A reference type
 */
class Setting {
    
    // MARK: - SettingType Enum
    
    /**
     Represents the type of a setting.
     */
    enum SettingType {
        case about
        case manager
        case processor
        case section
        case webpage
    }
    
    // MARK: - Properties
    
    /// The name of the setting.
    var name: String
    
    /// The type of the setting.
    var type: SettingType
    
    /// The value of the setting.
    var value: SettingValue
    
    // MARK: - Initialisers
    
    /**
     Creates a setting.
     
     - Parameters:
        - name: The name of the setting.
        - type: The type of the setting.
        - value: The value of the setting.
     */
    init(name: String, type: SettingType, value: SettingValue) {
        self.name = name
        self.type = type
        self.value = value
    }
}

// MARK: - Settings Class

/**
 Represents a collection of settings.
 
 A reference type is intentionally chosen as a simple way to keep settings data
 consistent across the app. This could cause problems in the future if actions
 occurred which could the settings to be updated concurrently.
 
 As settings can be nested, many of the public methods provided by this class
 support a `trail` parameter. This is a 'trail' of indices that drill down from
 the root.
 */
class Settings {
    
    // MARK: - SettingsError Enum
    
    /**
     Represents the error states in settings.
     */
    enum SettingsError: Error {
        case emptySection
        case noProcessor
        case notSection
    }
    
    // MARK: - Section Enum
    
    /**
     Represents the types of processors.
     */
    enum Section: Int {
        case enabled
        case builtIn
        case userAdded
    }
    
    // MARK: - Properties
    
    /// The collection of processors.
    var processors: [Processor]
    
    /// The collection of enabled processors.
    var enabledProcessors: [Processor]
    
    /// The path to the active processor.
    var selectedProcessorPath: IndexPath?
    
    /// The active processor.
    ///
    /// If a processor is not active, a processor will be selected to be the
    /// active processor.
    var selectedProcessor: Processor {
        if let processorPath = selectedProcessorPath, let selection = enabledProcessors.at(processorPath.row), selection.isEnabled {
            return selection
        }
        
        for processor in processors {
            if processor.isEnabled, let isSelected = PreferencesManager.processors[processor.filename]?.isSelected, isSelected {
                selectedProcessorPath = IndexPath(row: enabledProcessors.firstIndex(of: processor)!, section: enabledSection)
                return processor
            }
        }
        
        selectedProcessorPath = IndexPath(row: 0, section: enabledSection)
        return processors.first!
    }
    
    /// The settings.
    private var settings: [Setting]
    
    /// The raw value of the enabled section.
    private let enabledSection = Section.enabled.rawValue
    
    // MARK: - Initialisers
    
    /**
     Creates a collection of settings.
     
     - Parameters:
        - processors: All of the processors in the app.
     */
    init(processors: [Processor]) {
        self.processors = processors
        self.enabledProcessors = processors
            .filter({ $0.isEnabled })
            .sorted(by: {
                guard let first = PreferencesManager.processors[$0.filename]?.order else { return false }
                guard let second = PreferencesManager.processors[$1.filename]?.order else { return false }
                
                return first < second
            })
        self.selectedProcessorPath = nil
        self.settings = SettingsData.settings()
    }
    
    /**
     Creates a collection of settings and sets an active processor.
     
     - Parameters:
        - processors: All of the processors in the app.
        - processor: The active processor.
     
     - Throws: `processor` is not in the `procesors`
     */
    convenience init(processors: [Processor], selected processor: Processor) throws {
        self.init(processors: processors)
        
        guard let row = enabledProcessors.firstIndex(of: processor) else { throw SettingsError.noProcessor }
        self.selectedProcessorPath = IndexPath(row: row, section: enabledSection)
    }
    
    // MARK: - Processor Inserters and Removers
    
    /**
     Adds the processor.
     
     This method is used when the user adds a processor through the app.
     
     - Parameters:
        - processor: The processor to add.
     */
    func add(_ processor: Processor) {
        self.processors.append(processor)
        
        guard processor.isEnabled else { return }
        self.enabledProcessors.append(processor)
    }
    
    /**
     Removes the processor.
     
     This method is used when the user removes a process through the app.
     
     - Parameters:
        - processor: The processor to remove.
     */
    func remove(_ processor: Processor) {
        self.processors.remove(at: self.processors.firstIndex(of: processor)!)
        
        guard processor.isEnabled else { return }
        self.enabledProcessors.remove(at: self.enabledProcessors.firstIndex(of: processor)!)
    }

    // MARK: - Selection Updaters
    
    /**
     Resets the active processor.
     
     This method tries to reset the active processor to the first processor in
     the `enabledProcessors` collection. If that is not possible, it sets the
     active processor to `nil` and logs an error.
     */
    func resetSelectedProcessor() {
        if enabledProcessors.first != nil {
            selectedProcessorPath = IndexPath(row: 0, section: enabledSection)
        } else {
            NSLog("There are no enabled processors")
            selectedProcessorPath = nil
        }
    }
    
    /**
     Updates the active processor.
     
     This method tries to update the active processor to be the processor
     provided. If the processor does not exist in `enabledProcessors`, it sets
     the active processor to `nil` and logs an error.
     
     - Parameters:
        - processor: The processor to set as the active processor.
     */
    func updateSelectedProcessor(with processor: Processor) {
        if let row = enabledProcessors.firstIndex(of: processor) {
            selectedProcessorPath = IndexPath(row: row, section: enabledSection)
        } else {
            NSLog("The selected processor is not enabled")
            selectedProcessorPath = IndexPath(row: 0, section: enabledSection)
        }
    }
    
    // MARK: - Processor Checkers

    /**
     Checks whether the item at an index is a processor.
     
     - Parameters:
        - indexPath: The index of the item to check.
        - trail: The trail of nested index path (this might be empty).
     
     - Returns: Whether the item at an index is a processor.
     */
    func isProcessor(at indexPath: IndexPath, using trail: [Int]) -> Bool {
        return areProcessors(at: indexPath.section, using: trail)
    }
    
    /**
     Returns whether the section contains processors.
     
     - Parameters:
        - section: The section within the relevant table.
        - trail: The trail of nested index paths (this might be empty).
     
     - Returns: Whether the section is one that contains processors.
     */
    private func areProcessors(at section: Int, using trail: [Int]) -> Bool {
        return trail.isEmpty && section == 0
    }
    
    // MARK: - Row and Section Calculators
    
    /**
     Returns the number of rows in a section.
     
     - Parameters:
        - section: The section to analyse.
        - trail: The trail of nested index paths (this might be empty).
     
     - Throws: `section` does not exist within the nested structure defined by
               `trail`
     
     - Returns: The number of rows.
     */
    func numberOfRows(for section: Int, using trail: [Int] = []) throws -> Int {
        guard !areProcessors(at: section, using: trail) else { return enabledProcessors.count }
        
        let sectionSettings = try extractSettings(for: section, using: trail)
        return sectionSettings.count
    }
    
    /**
     Returns the number of sections.
     
     - Parameters:
        - trail: The trail of nested index paths (this might be empty).
     
     - Throws: The settings for this trail could not be extracted.
     
     - Returns: The number of sections.
     */
    func numberOfSections(using trail: [Int] = []) throws -> Int {
        let settings = try extractSettings(using: trail)
        return hasExtractableSettings(for: settings) ? settings.count : 1
    }
    
    // MARK: - Accessors
    
    /**
     Returns the header to display for the section.
     
     - Parameters:
        - section: The section to which the header relates.
        - trail: The trail of nested index paths (this might be empty).
     
     - Throws: The settings for this trail could not be extracted.
     
     - Returns: The header to display.
     */
    func header(for section: Int, using trail: [Int]) throws -> String? {
        let settings = try extractSettings(using: trail)
        return hasExtractableSettings(for: settings) ? settings[section].name : nil
    }
    
    /**
     Returns the setting for an index path.

     The difference between this and `item(at:using:)` is that this will not
     retrieve the processor if the index is within the list of enabled
     processors.

     - Parameters:
        - indexPath: The index path to check.
        - trail: The trail of nested index paths (this might be empty).
     
     - Throws: The settings for this trail could not be extracted.
     
     - Returns: The setting.
     */
    func setting(at indexPath: IndexPath, using trail: [Int]) throws -> Setting {
        let settings = try extractSettings(for: indexPath.section, using: trail)
        return settings[indexPath.row]
    }
    
    /**
     Returns the item for an index path.
     
     The difference between this and `setting(at:using:)` is that this will
     retrieve the processor if the index is within the list of enabled
     processors.
     
     - Parameters:
        - indexPath: The index path to check.
        - trail: The trail of nested index paths (this might be empty).
     
     - Throws: The settings for this trail could not be extracted.
     
     - Returns: The item.
     */
    func item(at indexPath: IndexPath, using trail: [Int]) throws -> SettingItem {
        if isProcessor(at: indexPath, using: trail) {
            return enabledProcessors[indexPath.row]
        } else {
            return try setting(at: indexPath, using: trail)
        }
    }
    
    // MARK: - Setting Extractors

    /**
     Extracts the settings for a trail
     
     This is a foundational method used by many other public methods. Because
     the `SettingsViewController` class can display various setting sections at
     arbitrary levels of nesting, it's necessary to be able to know where in the
     'stack' of settings we are located. This is the purpose of `trail`.
     
     - Parameters:
        - trail: The trail of nested index paths (this might be empty).
     
     - Throws: One of the 'sections' in `trail` was not a section.
     
     - Returns: An array of `Setting` objects.
     */
    private func extractSettings(using trail: [Int]) throws -> [Setting] {
        var result = settings
        
        for section in trail {
            guard result[section].value is [Setting] else { throw SettingsError.notSection }
            result = result[section].value as! [Setting]
        }
        
        return result
    }

    /**
     Extract the settings for a section in a trail.
     
     - Parameters:
        - section: The section to check.
        - trail: The trail of nested index paths (this might be empty).
     
     - Throws: The settings for `section` or `trail` could not be extracted.
     
     - Returns: An array of `Setting` objects.
     */
    private func extractSettings(for section: Int, using trail: [Int]) throws -> [Setting] {
        let parentSettings = try extractSettings(using: trail)
        
        // TODO: Not sure this works with deeply nested settings
        if hasExtractableSettings(for: parentSettings) {
            guard let sectionSettings = parentSettings[section].value as? [Setting] else { throw SettingsError.notSection }
            return sectionSettings
        } else if section == 0 {
            return parentSettings
        } else {
            throw SettingsError.notSection
        }
    }
    
    /**
     Checks whether there are extractable settings.
     
     If the first item in a collection of settings is not of type
     `Setting.SettingType.section` then we assume that there are no nested
     settings.
     
     - Parameters:
        - parent: The collection of `Setting` objects to check.
     
     - Returns: Whether there are nested settings or not.
     */
    private func hasExtractableSettings(for parent: [Setting]) -> Bool {
        guard let firstType = parent.first?.type else { return false }
        
        return firstType == .section
    }
}

// MARK: - SettingsManager Struct

/**
 Represents a manager of settings.
 
 Some people might call this a factory.
 */
struct SettingsManager {
    
    // MARK: - Properties
    
    /// The settings for the app.
    static var settings: Settings {
        if let settings = sharedSettings {
            return settings
        } else {
            sharedSettings = Settings(processors: Processor.all)
            return sharedSettings!
        }
    }
    
    /// The cache for the settings computed by `settings`.
    private static var sharedSettings: Settings?
}
