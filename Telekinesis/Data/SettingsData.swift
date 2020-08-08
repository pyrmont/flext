//
//  SettingsData.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 2/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

struct SettingsData {
    static func settings() -> [SettingModel] { [help(), general()] }
    
    private static func help() -> SettingModel {
        return SettingModel(name: "User Guide", type: .section, value: [
            SettingModel(name: "Adding Processors", type: .page, value: "page-adding"),
            SettingModel(name: "Writing Processors", type: .page, value: "page-writing")])
    }
    
    private static func licences() -> SettingModel {
        return SettingModel(name: "Licences", type: .section, value: [
            SettingModel(name: "Down", type: .page, value: "page-down-licence"),
            SettingModel(name: "cmark", type: .page, value: "page-cmark-licence")])
    }
    
    private static func general() -> SettingModel {
        return SettingModel(name: "General", type: .section, value: [
            SettingModel(name: "About", type: .page, value: "page-about"),
            SettingModel(name: "Contact", type: .page, value: "page-contact"),
            licences()])
    }
    
//    private static func processors() -> Setting {
//        return Setting(name: "Processors", type: .section, value: ProcessorModel.findAll().map {
//            Setting(name: $0.name, type: .processor, value: $0) })
//    }
}
