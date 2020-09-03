//
//  SettingsData.swift
//  Flext
//
//  Created by Michael Camilleri on 2/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation

// MARK: - SettingsData Struct

/**
 Represents the settings data.

 There are a number of ways that the settings data could be persisted within the
 Flext. The method chosen here is to create a struct with several static
 functions that return `Setting` elements that contain the information.

 This approach is somewhat brittle but is simple and easy to modify (at least
 with the amount of data contained in the struct).
 */
struct SettingsData {

    /**
     Returns the settings data for Flext.

     - Returns: The settings data.
     */
    static func settings() -> [Setting] {
        [processors(), management(), help(), general(), legal()]
    }

    /**
     Returns the help items.

     - Returns: The `Setting` object that represents the help items.
     */
    private static func help() -> Setting {
        return Setting(name: "User Guide", type: .section, value: [
            Setting(name: "Adding Processors", type: .webpage, value: Webpage(title: "User Guide", sourceFile: "help_adding.md")),
            Setting(name: "Removing Processors", type: .webpage, value: Webpage(title: "User Guide", sourceFile: "help_removing.md")),
            Setting(name: "Writing Processors", type: .webpage, value: Webpage(title: "User Guide", sourceFile: "help_writing.md"))])
    }

    /**
     Returns the legal items.

     - Returns: The `Setting` object that represents the legal items.
     */
    private static func legal() -> Setting {
        return Setting(name: "Legal", type: .section, value: [
            licences(),
            Setting(name: "Privacy Policy", type: .webpage, value: Webpage(title: "Legal", sourceFile: "legal_privacy.md"))])
    }

    /**
     Returns the licence items.

     - Returns: The `Setting` object that represents the licence items.
     */
    private static func licences() -> Setting {
        return Setting(name: "Licences", type: .section, value: [
            Setting(name: "cmark", type: .webpage, value: Webpage(title: "", sourceFile: "licence_cmark.md")),
            Setting(name: "commonmark.js", type: .webpage, value: Webpage(title: "", sourceFile: "licence_commonmarkjs.md")),
            Setting(name: "Down", type: .webpage, value: Webpage(title: "", sourceFile: "licence_down.md")),
            Setting(name: "Highlight.js", type: .webpage, value: Webpage(title: "", sourceFile: "licence_highlight.md"))])
    }

    /**
     Returns the manager item.

     - Returns: The `Setting` object that represents the manager item.
     */
    private static func management() -> Setting {
        return Setting(name: "Management", type: .section, value: [
            Setting(name: "Processors", type: .manager, value: "# Processors")])
    }

    /**
     Returns the general items.

     - Returns: The `Setting` object that represents the general item.
     */
    private static func general() -> Setting {
        return Setting(name: "General", type: .section, value: [
            Setting(name: "About", type: .about, value: ""),
            Setting(name: "Contact", type: .webpage, value: Webpage(title: "Contact", sourceFile: "general_contact.md")),
            Setting(name: "Source Code", type: .webpage, value: Webpage(title: "Source Code", sourceFile: "general_source.md"))])
    }

    /**
     Returns the processor item.

     This method returns an item that functions as a stub. It is used by the
     `SettingsViewController` class as a placeholder for listing the
     process that are enabled.

     - Returns: The `Setting` object that represents the processor item.
     */
    private static func processors() -> Setting {
        return Setting(name: "Enabled Processors", type: .section, value: [])
    }
}
