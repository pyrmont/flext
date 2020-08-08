//
//  SettingsViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeight: NSLayoutConstraint!
    
    @IBAction func unwindToSettings(unwindSegue: UIStoryboardSegue) { }
    
    var settings: SettingsModel!
    var trail: [Int]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settings = settings ?? SettingsModel(processors: ProcessorModel.findAll())
        trail = trail ?? []

        tableView.delegate = self
        tableView.dataSource = self
        
        if trail.isEmpty {
            tableView.allowsMultipleSelection = true
            tableView.selectRow(at: settings.selectedProcessorPath, animated: false, scrollPosition: .none)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? UITableViewCell {
            let indexPath = tableView.indexPath(for: sender)!
            
            if let section = segue.destination as? SettingsViewController {
                section.settings = settings
                section.trail = trail + [indexPath.section, indexPath.row]
                section.title = try! settings.setting(at: indexPath, using: trail).name
            } else if let page = segue.destination as? PageViewController {
                page.textKey = try! settings.setting(at: indexPath, using: trail).value as! String
            } else if let options = segue.destination as? ProcessorOptionsViewController {
                options.processor = settings.processors[indexPath.row]
            }
        } else {
            guard let editor = segue.destination as? EditorViewController else { return }
            editor.settings = settings
            editor.setupProcessor(using: settings.selectedProcessor!)
            editor.runProcessor()
        }
    }

    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        tableViewHeight.constant = tableView.contentSize.height
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func typeOfCell(for value: SettingValue) -> String {
        if let processor = value as? ProcessorModel {
            return processor.hasOptions ? "Processor Cell (Options)" : "Processor Cell"
        } else if value is [SettingModel] {
            return "Section Cell"
        } else {
            return "Page Cell"
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return try! settings.numberOfSections(using: trail)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return try! settings.numberOfRows(for: section, using: trail)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = try! settings.value(at: indexPath, using: trail)
        let cellType = typeOfCell(for: item)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType, for: indexPath)
        if item is ProcessorModel {
            cell.textLabel?.text = (item as! ProcessorModel).name
        } else {
            cell.textLabel?.text = try! settings.setting(at: indexPath, using: trail).name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedPaths = tableView.indexPathsForSelectedRows else { return indexPath }
        
        for selectedPath in selectedPaths {
            if (settings.isProcessor(at: indexPath, using: trail) && settings.isProcessor(at: selectedPath, using: trail)) || (!settings.isProcessor(at: indexPath, using: trail) && !settings.isProcessor(at: selectedPath, using: trail)) {
                tableView.deselectRow(at: selectedPath, animated: false)
            }
        }
        
        if settings.isProcessor(at: indexPath, using: trail) {
            settings.selectedProcessorPath = indexPath
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !settings.isProcessor(at: indexPath, using: trail) else { return }
        
        let selection = tableView.cellForRow(at: indexPath)
        selection?.isSelected = false
    }
}
