//
//  SettingsData.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 2/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

enum SettingType {
    case page
    case section
}

protocol SettingValue { }
extension ProcessorModel: SettingValue {}
extension Array: SettingValue where Element == Setting {}
extension String: SettingValue {}

struct Setting {
    var name: String
    var type: SettingType
    var value: SettingValue
}

struct Settings {
    var processors: [ProcessorModel]
    var selectedProcessorPath: IndexPath?
    
    var selectedProcessor: ProcessorModel { processors[selectedProcessorPath!.row] }
    
    private var settings: [Setting]
    
    init(processors: [ProcessorModel]) {
        self.processors = processors
        self.selectedProcessorPath = IndexPath(row: 0, section: 0)
        self.settings = SettingsData.settings()
    }
    
    init(processors: [ProcessorModel], selected processor: ProcessorModel) {
        self.processors = processors
        self.selectedProcessorPath = IndexPath(row: processors.firstIndex(of: processor)!, section: 0)
        self.settings = SettingsData.settings()
    }
    
    func isProcessor(at indexPath: IndexPath, using trail: [Int] = []) -> Bool {
        return trail.isEmpty && indexPath.section == 0
    }
    
    func numberOfRows(for section: Int, using trail: [Int] = []) -> Int {
        if trail.isEmpty {
            return section == 0 ? processors.count : (settings[section - 1].value as! [Setting]).count
        } else {
            let settings = extractSettings(using: trail)
            guard let firstType = settings.first?.type else { return 0 }
            if firstType == .section {
                return (settings[section].value as! [Setting]).count
            } else {
                return settings.count
            }
        }
    }
    
    func numberOfSections(using trail: [Int] = []) -> Int {
        if trail.isEmpty {
            return settings.count + 1
        } else {
            let settings = extractSettings(using: trail)
            guard let firstType = settings.first?.type else { return 0 }
            if firstType == .section {
                return settings.count
            } else {
                return 1
            }
        }
    }
    
    func section(at indexPath: IndexPath, using trail: [Int]) -> Int {
        if trail.isEmpty {
            return indexPath.section - 1
        } else {
            return indexPath.section
        }
    }
    
    func value(at indexPath: IndexPath, using trail: [Int] = []) -> SettingValue {
        if trail.isEmpty && indexPath.section == 0 {
            return processors[indexPath.row]
        } else {
            return setting(at: indexPath, using: trail).value
        }
    }
    
    func setting(at indexPath: IndexPath, using trail: [Int] = []) -> Setting {
        if trail.isEmpty {
            return (settings[indexPath.section - 1].value as! [Setting])[indexPath.row]
        } else {
            let settings = extractSettings(using: trail)
            let firstType = settings.first!.type
            if firstType == .section {
                return (settings[indexPath.section].value as! [Setting])[indexPath.row]
            } else {
                return settings[indexPath.row]
            }
        }
    }
    
    mutating func updateSelectedProcessor(with processor: ProcessorModel) {
        selectedProcessorPath = IndexPath(row: processors.firstIndex(of: processor)!, section: 0)
    }
    
    private func extractSettings(using trail: [Int]) -> [Setting] {
        guard !trail.isEmpty else { return settings }
        
        var result = settings[trail.first! - 1].value as! [Setting]
        for section in trail.dropFirst() {
            result = result[section].value as! [Setting]
        }
        
        return result
    }
}

struct SettingsData {
    static func settings() -> [Setting] { [help(), general()] }
    
    private static func help() -> Setting {
        return Setting(name: "User Guide", type: .section, value: [
            Setting(name: "Adding Processors", type: .page, value: "page-adding"),
            Setting(name: "Writing Processors", type: .page, value: "page-writing")])
    }
    
    private static func licences() -> Setting {
        return Setting(name: "Licences", type: .section, value: [
            Setting(name: "Down", type: .page, value: "page-down-licence"),
            Setting(name: "cmark", type: .page, value: "page-cmark-licence")])
    }
    
    private static func general() -> Setting {
        return Setting(name: "General", type: .section, value: [
            Setting(name: "About", type: .page, value: "page-about"),
            Setting(name: "Contact", type: .page, value: "page-contact"),
            licences()])
    }
    
//    private static func processors() -> Setting {
//        return Setting(name: "Processors", type: .section, value: ProcessorModel.findAll().map {
//            Setting(name: $0.name, type: .processor, value: $0) })
//    }
}
