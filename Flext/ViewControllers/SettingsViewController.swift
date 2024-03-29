//
//  SettingsViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2021 Michael Camilleri. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0.

import UIKit

/**
 Displays the Settings section.

 Flext aims to provide a simple and clean interface in the editor. Part of the
 way this is achieved, is by moving everything that isn't necessary to be
 visible on screen to the Settings section.

 The result of this is that the Sections setting contains several different
 'types' of Settings. There are the enabled processors (that the user can select
 from to be the active processor), there is a processor manager, there is a user
 guide, there is a collection of information screens (e.g. about, contact) and
 there is a collection of legal screens (e.g. licences, privacy).

 To reduce duplication, the Settings section can work at multiple levels of
 depth. A particular Settings instance keeps sense of where it is relative to
 the root Settings section by use of a `trail` property.

 The data for settings is generated by the `SettingsManager`.
 */
class SettingsViewController: UIViewController {

    // MARK: - IB Outlet Values

    @IBOutlet var navigationBar: UINavigationItem!
    @IBOutlet var tableView: UITableView!

    // MARK: - Properties

    /// The settings for Flext.
    var settings: Settings = SettingsManager.settings

    /// The trail back to the root.
    var trail: [Int]!

    // TODO: Consider whether there is a way to have the Settings section detect
    // automatically whether a refresh is necessary. The way this is implemented
    // complects the Settings implementation logic with other view controllers.

    /// The status of whether the Sections section needs to be refreshed.
    ///
    /// This value is needed because the Manager section can result in the
    /// list of active processors changing. By exposing this property, the
    /// Manager section can set this to `true` before returning.
    var needsRefresh = false

    // MARK: - Controller Loading

    override func viewDidLoad() {
        super.viewDidLoad()

        trail = trail ?? []

        tableView.delegate = self
        tableView.dataSource = self

        if trail.isEmpty {
//            tableView.allowsMultipleSelection = true
            selectProcessor(at: settings.selectedProcessorPath)
        } else {
            navigationBar.rightBarButtonItem = nil
        }
    }

    // MARK: - Segues

    /**
     Unwinds to the Settings section.

     This method is necessary for other screens to be able to unwind back to the
     Settings section. It is intentionally empty.

     - Parameters:
        - unwindSegue: The unwinding segue.
     */
    @IBAction func unwindToSettings(unwindSegue: UIStoryboardSegue) { }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        needsRefresh = false

        if let sender = sender as? UITableViewCell {
            let indexPath = tableView.indexPath(for: sender)!
            let item = try! settings.item(at: indexPath, using: trail)

            if segue.destination is ManagerViewController {
                needsRefresh = true
            } else if let options = segue.destination as? OptionsViewController {
                options.processor = item as? Processor
            } else if let section = segue.destination as? SettingsViewController {
                section.settings = settings
                section.trail = trail + [indexPath.section, indexPath.row]
                section.title = item.name
            } else if let viewer = segue.destination as? WebpageViewController {
                viewer.webpage = (item as! Setting).value as? Webpage
            }
        } else if let editor = segue.destination as? EditorViewController {
            editor.returnToEditor()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if needsRefresh {
            tableView.reloadData()
            selectProcessor(at: settings.selectedProcessorPath)
        }
    }

    // MARK: - Processor Selection

    /**
     Selects the active processor.

     Flext lists the enabled processors in the Settings section. When a user
     selects one of these processors, Flext needs to be able to update the
     processor that is registered in Flext's settings as being the active
     processor.

     - Parameters:
        - indexPath: The index of the processor that is being selected. This is
                     the index within the list of enabled processors.
     */
    func selectProcessor(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        settings.selectedProcessorPath = indexPath
    }

    /**
     Deslects the formerly active processor.

     As noted above, the user can select the active processor from the list of
     enabled processors. This method deselects the processor that was
     immediately active before this selection.

     - Parameters:
        - indexPath: The index of the processor that is being deselected. This
                     is the index within the list of enabled processors.
     */
    func deselectProcessor(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

// MARK: - Data Source and Delegate

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Sections

    func numberOfSections(in tableView: UITableView) -> Int {
        return try! settings.numberOfSections(using: trail)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return try! settings.header(for: section, using: trail)
    }

    // MARK: - Rows

    /**
     Returns the type of cell depending on the item.

     The table view's prototype cells are each assigned identified in Interface
     Builder. This method examines the `settingType` property of each
     `SettingItem` and returns the name of the appropriate prototype.

     - Parameters:
        - item: The setting item that will be represented by the table cell.

     - Returns: The name of the prototype cell.
     */
    func typeOfCell(for item: SettingItem) -> String {
        switch item.settingType {
        case .about:
            return "About Cell"
        case .manager:
            return "Manager Cell"
        case .processor:
            let processor = item as! Processor
            return processor.hasOptions ? "Processor Cell (Options)" : "Processor Cell"
        case .section:
            return "Section Cell"
        case .webpage:
            return "Webpage Cell"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return try! settings.numberOfRows(for: section, using: trail)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = try! settings.item(at: indexPath, using: trail)
        let cellType = typeOfCell(for: item)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType, for: indexPath)
        cell.textLabel?.text = item.name

        if let setting = item as? Setting {
            if setting.type == .manager {
                let processor_counter = setting.value as! String
                cell.detailTextLabel?.text = processor_counter.replacingOccurrences(of: "#", with: String(settings.processors.count))
            }
        }

        return cell
    }

    // MARK: - Selection

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedPaths = tableView.indexPathsForSelectedRows else { return indexPath }

        for selectedPath in selectedPaths {
            if settings.isProcessor(at: indexPath, using: trail) && settings.isProcessor(at: selectedPath, using: trail) {
                deselectProcessor(at: selectedPath)
            }
        }

        if settings.isProcessor(at: indexPath, using: trail) {
            selectProcessor(at: indexPath)
        }

        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !settings.isProcessor(at: indexPath, using: trail) else { return }
        guard let selection = tableView.cellForRow(at: indexPath) else { return }
        selection.isSelected = false
    }

    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard settings.isProcessor(at: indexPath, using: trail) else { return indexPath }
        return nil
    }
}
