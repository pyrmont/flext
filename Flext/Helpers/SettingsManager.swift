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
