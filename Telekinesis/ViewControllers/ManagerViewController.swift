//
//  ManagerViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 9/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class ManagerTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var enabledToggle: UISwitch?
    
    var processor: ProcessorModel!
}

class ManagerViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var instructionsLabel: UILabel!
    
    @IBAction func enableProcessor(_ sender: UISwitch) {
        guard let cell = sender.superview?.superview as? ManagerTableViewCell else { return }
        
        cell.processor.isEnabled = sender.isOn
        
        if sender.isOn {
            let rowIndex = settings.enabledProcessors.count
            settings.enabledProcessors.append(cell.processor)
            tableView.insertRows(at: [IndexPath(row: rowIndex, section: 0)], with: .automatic)
        } else {
            guard let rowIndex = settings.enabledProcessors.firstIndex(of: cell.processor) else { return }
            settings.enabledProcessors.remove(at: rowIndex)
            tableView.deleteRows(at: [IndexPath(row: rowIndex, section: 0)], with: .automatic)
            if settings.selectedProcessorPath?.row == rowIndex {
                settings.resetSelectedProcessor()
            }
        }
            
        for cell in tableView.visibleCells {
            guard let toggle = (cell as! ManagerTableViewCell).enabledToggle else { continue }
            toggle.isEnabled = settings.enabledProcessors.count == 1 ? !toggle.isOn : true
        }
    }
    
    var settings: SettingsModel!
    var builtInProcessors: [ProcessorModel] = []
    var userAddedProcessors: [ProcessorModel] = []
    
    var isDeleting: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for processor in settings.processors {
            switch processor.type {
            case .builtIn:
                builtInProcessors.append(processor)
            case .userAdded:
                userAddedProcessors.append(processor)
            }
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setEditing(true, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let editor = segue.destination as? EditorViewController else { return }
        editor.setupProcessor(using: settings.selectedProcessor!)
        editor.runProcessor()
    }
}

extension ManagerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return userAddedProcessors.isEmpty ? 2 : 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return builtInProcessors.count
        case 2:
            return userAddedProcessors.count
        default:
            return settings.enabledProcessors.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Built-In Processors"
        case 2:
            return "User-Added Processors"
        default:
            return "Ordering"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var processor: ProcessorModel
        var cellType: String
        
        switch indexPath.section {
        case 1:
            processor = builtInProcessors[indexPath.row]
            cellType = "Enabling Cell"
        case 2:
            processor = userAddedProcessors[indexPath.row]
            cellType = "Enabling Cell"
        default:
            processor = settings.enabledProcessors[indexPath.row]
            cellType = "Reordering Cell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType, for: indexPath) as! ManagerTableViewCell
        
        cell.titleLabel?.text = processor.name
        
        if let toggle = cell.enabledToggle {
            toggle.isOn = processor.isEnabled
            toggle.isEnabled = settings.enabledProcessors.count == 1 ? !toggle.isOn : true
        }
        
        cell.processor = processor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ? true : false
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard sourceIndexPath.section == 0 else { return sourceIndexPath }
        
        if proposedDestinationIndexPath.section != 0 {
            let lastRowIndex = self.tableView(tableView, numberOfRowsInSection: sourceIndexPath.section) - 1
            return IndexPath(row: lastRowIndex, section: sourceIndexPath.section)
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let processor = settings.enabledProcessors.remove(at: sourceIndexPath.row)
        settings.enabledProcessors.insert(processor, at: destinationIndexPath.row)
        if settings.selectedProcessorPath?.row == sourceIndexPath.row {
            settings.selectedProcessorPath?.row = destinationIndexPath.row
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard isDeleting && indexPath.section == 2 else { return .none }
        return .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        guard isDeleting && indexPath.section == 2 else { return false }
        return true
    }
}
