//
//  ActionSettingsViewController.swift
//  ActionExtension
//
//  Created by Michael Camilleri on 19/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

// MARK: - Action Settings Table View Cell Definition

class ActionSettingsTableViewCell: UITableViewCell {
    let selectedCellImage = UIImage(systemName: "smallcircle.fill.circle.fill")
    var originalCellImage: UIImage!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            originalCellImage = originalCellImage ?? imageView?.image
            imageView?.image = selectedCellImage
        } else {
            imageView?.image = originalCellImage ?? imageView?.image
        }
    }
}

class ActionSettingsViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    
    var settings: Settings = SettingsManager.settings

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        selectProcessor(at: IndexPath(row: UserDefaults.standard.integer(forKey: "selectedIndex"), section: 0))
    }
    
    // MARK: - Processor Selection
    
    func selectProcessor(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        UserDefaults.standard.set(indexPath.row, forKey: "selectedIndex")
    }
    
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

