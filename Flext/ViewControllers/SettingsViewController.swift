//
//  SettingsViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

// MARK: - Settings Processor Table View Cell Definition

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

// MARK: - Settings View Controller Definition

class SettingsViewController: UIViewController {
    @IBOutlet var navigationBar: UINavigationItem!
    @IBOutlet var tableView: UITableView!
    
    var settings: Settings = SettingsManager.settings
    var trail: [Int]!
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
            } else if !settings.isProcessor(at: indexPath, using: trail) && !settings.isProcessor(at: selectedPath, using: trail) {
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
        guard let selection = tableView.cellForRow(at: indexPath) else { return }
        selection.isSelected = false
    }

    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard settings.isProcessor(at: indexPath, using: trail) else { return indexPath }
        return nil
    }
}
