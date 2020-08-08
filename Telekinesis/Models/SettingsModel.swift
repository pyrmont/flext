//
//  SettingsModel.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 8/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

enum SettingType {
    case page
    case section
}

protocol SettingValue { }
extension ProcessorModel: SettingValue {}
extension Array: SettingValue where Element == SettingModel {}
extension String: SettingValue {}

struct SettingModel {
    var name: String
    var type: SettingType
    var value: SettingValue
}

struct SettingsModel {
    enum SettingsError: Error {
        case emptySection
        case invalidCast
        case noProcessor
        case notSection
    }
    
    var processors: [ProcessorModel]
    var selectedProcessorPath: IndexPath?
    
    var selectedProcessor: ProcessorModel? {
        guard let row = selectedProcessorPath?.row else { return nil }
        return processors[row]
    }
    
    private var settings: [SettingModel]
    
    // MARK: - Initialisers
    
    init(processors: [ProcessorModel]) {
        self.processors = processors
        self.selectedProcessorPath = IndexPath(row: 0, section: 0)
        self.settings = SettingsData.settings()
    }
    
    init(processors: [ProcessorModel], selected processor: ProcessorModel) throws {
        self.processors = processors
        
        guard let row = processors.firstIndex(of: processor) else { throw SettingsError.noProcessor }
        self.selectedProcessorPath = IndexPath(row: row, section: 0)
        
        self.settings = SettingsData.settings()
    }

    // MARK: - Selection Updaters
    
    mutating func updateSelectedProcessor(with processor: ProcessorModel) {
        selectedProcessorPath = IndexPath(row: processors.firstIndex(of: processor)!, section: 0)
    }
    
    // MARK: - Processor Checkers

    func isProcessor(at indexPath: IndexPath, using trail: [Int]) -> Bool {
        return isProcessor(at: indexPath.section, using: trail)
    }
    
    func isProcessor(at section: Int, using trail: [Int]) -> Bool {
        return trail.isEmpty && section == 0
    }
    
    func isProcessor(using trail: [Int]) -> Bool {
        return trail.isEmpty
    }
    
    // MARK: - Row and Section Calculators
    
    func numberOfRows(for section: Int, using trail: [Int] = []) throws -> Int {
        guard !isProcessor(at: section, using: trail) else { return processors.count }
        
        let sectionSettings = try extractSettings(for: section, using: trail)
        return sectionSettings.count
    }
    
    func numberOfSections(using trail: [Int] = []) throws -> Int {
        guard !isProcessor(using: trail) else { return settings.count + 1 }

        let settings = try extractSettings(using: trail)
        return hasExtractableSettings(for: settings) ? settings.count : 1
    }
    
    // MARK: - Accessors
    
    func setting(at indexPath: IndexPath, using trail: [Int]) throws -> SettingModel {
        let settings = try extractSettings(for: indexPath.section, using: trail)
        return settings[indexPath.row]
    }
    
    func value(at indexPath: IndexPath, using trail: [Int]) throws -> SettingValue {
        if isProcessor(at: indexPath, using: trail) {
            return processors[indexPath.row]
        } else {
            return try setting(at: indexPath, using: trail).value
        }
    }
    
    // MARK: - Setting Extractors

    private func extractSettings(using trail: [Int]) throws -> [SettingModel] {
        guard !isProcessor(using: trail) else { return settings }
        guard var result = settings[trail.first! - 1].value as? [SettingModel] else { throw SettingsError.notSection }
        for section in trail.dropFirst() {
            guard result[section].value is [SettingModel] else { throw SettingsError.notSection }
            result = result[section].value as! [SettingModel]
        }
        return result
    }

    private func extractSettings(for section: Int, using trail: [Int]) throws -> [SettingModel] {
        let adjustedSection = trail.isEmpty ? section - 1 : section
        let parentSettings = try extractSettings(using: trail)
        
        // TODO: Not sure this works with deeply nested settings
        if hasExtractableSettings(for: parentSettings) {
            guard let sectionSettings = parentSettings[adjustedSection].value as? [SettingModel] else { throw SettingsError.notSection }
            return sectionSettings
        } else if adjustedSection == 0 {
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
