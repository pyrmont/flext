//
//  SettingsData.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 2/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

struct SettingsData {
    static func settings() -> [Setting] { [processors(), management(), help(), general()] }
    
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
    
    private static func management() -> Setting {
        return Setting(name: "Management", type: .section, value: [
            Setting(name: "Processors", type: .manager, value: "# Processors")])
    }
    
    private static func general() -> Setting {
        return Setting(name: "General", type: .section, value: [
            Setting(name: "About", type: .page, value: "page-about"),
            Setting(name: "Contact", type: .page, value: "page-contact"),
            licences()])
    }
    
    private static func processors() -> Setting {
        return Setting(name: "Enabled Processors", type: .section, value: [])
    }
}
