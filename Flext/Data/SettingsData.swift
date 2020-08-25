//
//  SettingsData.swift
//  Flext
//
//  Created by Michael Camilleri on 2/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

struct SettingsData {
    static func settings() -> [Setting] { [processors(), management(), help(), general()] }
    
    private static func help() -> Setting {
        return Setting(name: "User Guide", type: .section, value: [
            Setting(name: "Adding Processors", type: .webpage, value: Webpage(title: "User Guide", sourceFile: "help_adding.md")),
            Setting(name: "Removing Processors", type: .webpage, value: Webpage(title: "User Guide", sourceFile: "help_removing.md")),
            Setting(name: "Writing Processors", type: .webpage, value: Webpage(title: "User Guide", sourceFile: "help_writing.md"))])
    }
    
    private static func licences() -> Setting {
        return Setting(name: "Licences", type: .section, value: [
            Setting(name: "Flext", type: .webpage, value: Webpage(title: "", sourceFile: "licence_flext.md")),
            Setting(name: "cmark", type: .webpage, value: Webpage(title: "", sourceFile: "licence_cmark.md")),
            Setting(name: "Down", type: .webpage, value: Webpage(title: "", sourceFile: "licence_down.md")),
            Setting(name: "Highlight.js", type: .webpage, value: Webpage(title: "", sourceFile: "licence_highlight.md"))])
    }
    
    private static func management() -> Setting {
        return Setting(name: "Management", type: .section, value: [
            Setting(name: "Processors", type: .manager, value: "# Processors")])
    }
    
    private static func general() -> Setting {
        return Setting(name: "General", type: .section, value: [
            Setting(name: "About", type: .about, value: ""),
            Setting(name: "Contact", type: .webpage, value: Webpage(title: "Contact", sourceFile: "general_contact.md")),
            Setting(name: "Privacy", type: .webpage, value: Webpage(title: "Privacy", sourceFile: "general_privacy.md")),
            licences()])
    }
    
    private static func processors() -> Setting {
        return Setting(name: "Enabled Processors", type: .section, value: [])
    }
}
