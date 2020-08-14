//
//  SettingsModel.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 8/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

enum SettingType {
    case manager
    case page
    case processor
    case processors
    case section
}

protocol SettingValue { }
extension Array: SettingValue where Element == SettingModel {}
extension String: SettingValue {}

protocol SettingItem {
    var name: String { get }
}

extension ProcessorModel: SettingItem {}

class SettingModel: SettingItem {
    var name: String
    var type: SettingType
    var value: SettingValue
    
    init(name: String, type: SettingType, value: SettingValue) {
        self.name = name
        self.type = type
        self.value = value
    }
}

class SettingsModel {
    enum SettingsError: Error {
        case emptySection
        case invalidCast
        case noProcessor
        case notSection
    }
    
    var processors: [ProcessorModel]
    var enabledProcessors: [ProcessorModel]
    var selectedProcessorPath: IndexPath?
    
    var selectedProcessor: ProcessorModel? {
        guard let row = selectedProcessorPath?.row else { return nil }
        guard let selection = enabledProcessors.at(row) else { return nil }
        guard selection.isEnabled else { return nil }
        return selection
    }
    
    private var settings: [SettingModel]
    
    // MARK: - Initialisers
    
    init(processors: [ProcessorModel]) {
        self.processors = processors
        self.enabledProcessors = processors.filter { $0.isEnabled }
        self.selectedProcessorPath = IndexPath(row: 0, section: 0)
        self.settings = SettingsData.settings()
    }
    
    init(processors: [ProcessorModel], selected processor: ProcessorModel) throws {
        self.processors = processors
        self.enabledProcessors = processors.filter { $0.isEnabled }
        
        guard let row = enabledProcessors.firstIndex(of: processor) else { throw SettingsError.noProcessor }
        self.selectedProcessorPath = IndexPath(row: row, section: 0)
        
        self.settings = SettingsData.settings()
    }
    
    // MARK: - Processor Inserters and Removers
    
    func add(_ processor: ProcessorModel) {
        self.processors.append(processor)
        
        guard processor.isEnabled else { return }
        self.enabledProcessors.append(processor)
    }
    
    func remove(_ processor: ProcessorModel) {
        self.processors.remove(at: self.processors.firstIndex(of: processor)!)
        
        guard processor.isEnabled else { return }
        self.enabledProcessors.remove(at: self.enabledProcessors.firstIndex(of: processor)!)
    }

    // MARK: - Selection Updaters
    
    func resetSelectedProcessor() {
        if enabledProcessors.first != nil {
            selectedProcessorPath = IndexPath(row: 0, section: 0)
        } else {
            print("There are no enabled processors")
            selectedProcessorPath = nil
        }
    }
    
    func updateSelectedProcessor(with processor: ProcessorModel) {
        if let row = enabledProcessors.firstIndex(of: processor) {
            selectedProcessorPath = IndexPath(row: row, section: 0)
        } else {
            print("The selected processor is not enabled")
            selectedProcessorPath = IndexPath(row: 0, section: 0)
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
    
    func setting(at indexPath: IndexPath, using trail: [Int]) throws -> SettingModel {
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

    private func extractSettings(using trail: [Int]) throws -> [SettingModel] {
        var result = settings
        
        for section in trail {
            guard result[section].value is [SettingModel] else { throw SettingsError.notSection }
            result = result[section].value as! [SettingModel]
        }
        
        return result
    }

    private func extractSettings(for section: Int, using trail: [Int]) throws -> [SettingModel] {
        let parentSettings = try extractSettings(using: trail)
        
        // TODO: Not sure this works with deeply nested settings
        if hasExtractableSettings(for: parentSettings) {
            guard let sectionSettings = parentSettings[section].value as? [SettingModel] else { throw SettingsError.notSection }
            return sectionSettings
        } else if section == 0 {
            return parentSettings
        } else {
            throw SettingsError.notSection
        }
    }
    
    private func hasExtractableSettings(for parent: [SettingModel]) -> Bool {
        guard let firstType = parent.first?.type else {
            print("The parent was empty.")
            return false
        }
        
        return firstType == .section
    }
}
