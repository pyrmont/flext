//
//  SettingsManager.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 15/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

protocol SettingValue { }
extension Array: SettingValue where Element == Setting {}
extension String: SettingValue {}

protocol SettingItem {
    var name: String { get }
    var settingType: Setting.SettingType { get }
}

extension Processor: SettingItem {
    var settingType: Setting.SettingType { .processor }
}

class Setting: SettingItem {
    enum SettingType {
        case manager
        case page
        case processor
        case section
    }
    
    var name: String
    var type: SettingType
    var value: SettingValue
    
    var settingType: SettingType { type }
    
    init(name: String, type: SettingType, value: SettingValue) {
        self.name = name
        self.type = type
        self.value = value
    }
}

class Settings {
    enum SettingsError: Error {
        case emptySection
        case noProcessor
        case notSection
    }
    
    var processors: [Processor]
    var enabledProcessors: [Processor]
    var selectedProcessorPath: IndexPath?
    
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
    
    private var settings: [Setting]
    private let enabledSection = ManagerViewController.Section.enabled.rawValue
    
    // MARK: - Initialisers
    
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
    
    convenience init(processors: [Processor], selected processor: Processor) throws {
        self.init(processors: processors)
        
        guard let row = enabledProcessors.firstIndex(of: processor) else { throw SettingsError.noProcessor }
        self.selectedProcessorPath = IndexPath(row: row, section: enabledSection)
    }
    
    // MARK: - Processor Inserters and Removers
    
    func add(_ processor: Processor) {
        self.processors.append(processor)
        
        guard processor.isEnabled else { return }
        self.enabledProcessors.append(processor)
    }
    
    func remove(_ processor: Processor) {
        self.processors.remove(at: self.processors.firstIndex(of: processor)!)
        
        guard processor.isEnabled else { return }
        self.enabledProcessors.remove(at: self.enabledProcessors.firstIndex(of: processor)!)
    }

    // MARK: - Selection Updaters
    
    func resetSelectedProcessor() {
        if enabledProcessors.first != nil {
            selectedProcessorPath = IndexPath(row: 0, section: enabledSection)
        } else {
            NSLog("There are no enabled processors")
            selectedProcessorPath = nil
        }
    }
    
    func updateSelectedProcessor(with processor: Processor) {
        if let row = enabledProcessors.firstIndex(of: processor) {
            selectedProcessorPath = IndexPath(row: row, section: enabledSection)
        } else {
            NSLog("The selected processor is not enabled")
            selectedProcessorPath = IndexPath(row: 0, section: enabledSection)
        }
    }
    
    // MARK: - Processor Checkers

    func isProcessor(at indexPath: IndexPath, using trail: [Int]) -> Bool {
        return areProcessors(at: indexPath.section, using: trail)
    }
    
    func areProcessors(at section: Int, using trail: [Int]) -> Bool {
        return trail.isEmpty && section == 0
    }
    
    // MARK: - Row and Section Calculators
    
    func numberOfRows(for section: Int, using trail: [Int] = []) throws -> Int {
        guard !areProcessors(at: section, using: trail) else { return enabledProcessors.count }
        
        let sectionSettings = try extractSettings(for: section, using: trail)
        return sectionSettings.count
    }
    
    func numberOfSections(using trail: [Int] = []) throws -> Int {
        let settings = try extractSettings(using: trail)
        return hasExtractableSettings(for: settings) ? settings.count : 1
    }
    
    // MARK: - Accessors
    
    func header(for section: Int, using trail: [Int]) throws -> String? {
        let settings = try extractSettings(using: trail)
        return hasExtractableSettings(for: settings) ? settings[section].name : nil
    }
    
    func setting(at indexPath: IndexPath, using trail: [Int]) throws -> Setting {
        let settings = try extractSettings(for: indexPath.section, using: trail)
        return settings[indexPath.row]
    }
    
    func item(at indexPath: IndexPath, using trail: [Int]) throws -> SettingItem {
        if isProcessor(at: indexPath, using: trail) {
            return enabledProcessors[indexPath.row]
        } else {
            return try setting(at: indexPath, using: trail)
        }
    }
    
    // MARK: - Setting Extractors

    private func extractSettings(using trail: [Int]) throws -> [Setting] {
        var result = settings
        
        for section in trail {
            guard result[section].value is [Setting] else { throw SettingsError.notSection }
            result = result[section].value as! [Setting]
        }
        
        return result
    }

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
    
    private func hasExtractableSettings(for parent: [Setting]) -> Bool {
        guard let firstType = parent.first?.type else { return false }
        
        return firstType == .section
    }
}

struct SettingsManager {
    static var settings: Settings {
        if let settings = sharedSettings {
            return settings
        } else {
            sharedSettings = Settings(processors: Processor.all)
            return sharedSettings!
        }
    }
    
    private static var sharedSettings: Settings?
}
