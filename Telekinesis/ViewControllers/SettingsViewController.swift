//
//  SettingsViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class SettingsProcessorTableViewCell: UITableViewCell {
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
            selectProcessor(at: settings.selectedProcessorPath)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? UITableViewCell {
            let indexPath = tableView.indexPath(for: sender)!
            let item = try! settings.item(at: indexPath, using: trail)
            
            if let manager = segue.destination as? ManagerViewController {
                manager.settings = settings
            } else if let options = segue.destination as? ProcessorOptionsViewController {
                options.processor = item as? ProcessorModel
            } else if let page = segue.destination as? PageViewController {
                page.textKey = (item as! SettingModel).value as! String
            } else if let section = segue.destination as? SettingsViewController {
                section.settings = settings
                section.trail = trail + [indexPath.section, indexPath.row]
                section.title = item.name
            }
            
        } else {
            guard let editor = segue.destination as? EditorViewController else { return }
            editor.setupProcessor(using: settings.selectedProcessor!)
            editor.runProcessor()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        tableViewHeight.constant = tableView.contentSize.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if trail.isEmpty {
            tableView.reloadData()
            selectProcessor(at: settings.selectedProcessorPath)
        }

    }
    
    func selectProcessor(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        settings.selectedProcessorPath = indexPath
    }
    
    func deselectProcessor(at indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func typeOfCell(for item: SettingItem) -> String {
        if let processor = item as? ProcessorModel {
            return processor.hasOptions ? "Processor Cell (Options)" : "Processor Cell"
        } else if let setting = item as? SettingModel {
            switch setting.type {
            case .manager:
                return "Manager Cell"
            case .page:
                return "Page Cell"
            case .section:
                return "Section Cell"
            default:
                return "Page Cell"
            }
        } else {
            return ""
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return try! settings.numberOfSections(using: trail)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return try! settings.numberOfRows(for: section, using: trail)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return try! settings.header(for: section, using: trail)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = try! settings.item(at: indexPath, using: trail)
        let cellType = typeOfCell(for: item)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType, for: indexPath)
        cell.textLabel?.text = item.name
        
        if let setting = item as? SettingModel {
            if setting.type == .manager {
                let processor_counter = setting.value as! String
                cell.detailTextLabel?.text = processor_counter.replacingOccurrences(of: "#", with: String(settings.processors.count))
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard settings.isProcessor(at: indexPath, using: trail) else { return indexPath }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedPaths = tableView.indexPathsForSelectedRows else { return indexPath }
        
        for selectedPath in selectedPaths {
            if (settings.isProcessor(at: indexPath, using: trail) && settings.isProcessor(at: selectedPath, using: trail)) {
                deselectProcessor(at: selectedPath)
            } else if (!settings.isProcessor(at: indexPath, using: trail) && !settings.isProcessor(at: selectedPath, using: trail)) {
                tableView.deselectRow(at: selectedPath, animated: false)
            }
        }
        
        if settings.isProcessor(at: indexPath, using: trail) {
            selectProcessor(at: indexPath)
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !settings.isProcessor(at: indexPath, using: trail) else { return }
        
        let selection = tableView.cellForRow(at: indexPath)
        selection?.isSelected = false
    }
}
