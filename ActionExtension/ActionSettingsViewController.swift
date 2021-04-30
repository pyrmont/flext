//
//  ActionSettingsViewController.swift
//  ActionExtension
//
//  Created by Michael Camilleri on 19/8/20.
//  Copyright © 2021 Michael Camilleri. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0.

import UIKit

/**
 Displays the settings for the action extension.

 Most of the settings that are available through the Flext app are not
 accessible using the action extension. The exception is the active processor.
 This view controller is responsible for displaying the list of enabled
 processors and allowing the user to change which processor is active.
 */
class ActionSettingsViewController: UIViewController {

    // MARK: - IB Outlet Values

    @IBOutlet var tableView: UITableView!

    // MARK: - Properties

    /// The settings for Flext.
    var settings: Settings = SettingsManager.settings

    // MARK: - Controller Loading

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        selectProcessor(at: IndexPath(row: UserDefaults.standard.integer(forKey: "selectedIndex"), section: 0))
    }

    // MARK: - Processor Selection

    /**
     Selects the active processor.

     The active processor is the processor used by the view controller to
     process the text.

     - Parameters:
        - indexPath: The index of the processor that is being selected. This is
                     the index within the list of enabled processors.
     */
    func selectProcessor(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        UserDefaults.standard.set(indexPath.row, forKey: "selectedIndex")
    }

    /**
     Deselects the formerly active processor.

     - Parameters:
        - indexPath: The index of the processor that is being selected. This is
                     the index within the list of enabled processors.
     */
    func deselectProcessor(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

// MARK: - Data Source and Delegate

extension ActionSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Sections

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Processors"
    }

    // MARK: - Rows

    /**
     Returns the type of cell to use.

     The table view's prototype cells are each assigned identified in Interface
     Builder. At present, there is only one type of cell to use.

     - Parameters:
        - item: The setting item that will be represented by the table cell.

     - Returns: The name of the prototype cell.
     */
    func typeOfCell(for item: SettingItem) -> String {
        return "Cell"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.enabledProcessors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = settings.enabledProcessors[indexPath.row]
        let cellType = typeOfCell(for: item)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType, for: indexPath)
        cell.textLabel?.text = item.name

        return cell
    }

    // MARK: - Selection

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedPaths = tableView.indexPathsForSelectedRows else { return indexPath }

        for selectedPath in selectedPaths {
            deselectProcessor(at: selectedPath)
        }

        selectProcessor(at: indexPath)

        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }

    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}

