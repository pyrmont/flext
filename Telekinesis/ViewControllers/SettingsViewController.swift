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
    
    var settings: [Setting]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if settings == nil {
            settings = SettingsData.settings()
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let sender = sender as? UITableViewCell else { return }
        let indexPath = tableView.indexPath(for: sender)!
        
        guard let items = settings[indexPath.section].value as? [Setting] else { return }
        let item = items[indexPath.row]

        if let section = segue.destination as? SettingsViewController {
            section.settings = [item]
            section.title = item.name
        } else if let page = segue.destination as? PageViewController {
            page.textKey = item.value as! String
        } else if let editor = segue.destination as? EditorViewController {
            editor.setupProcessor(using: item.value as! ProcessorModel)
            editor.runProcessor()
        } else if let options = segue.destination as? ProcessorOptionsViewController {
            options.processor = item.value as? ProcessorModel
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        tableViewHeight.constant = tableView.contentSize.height
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func typeOfCell(for item: Setting) -> String {
        switch item.type {
        case .section:
            return "Section Cell"
        case .page:
            return "Page Cell"
        case .processor:
            let processor = item.value as! ProcessorModel
            if (processor.hasOptions) {
                return "Processor Cell (Options)"
            } else {
                return "Processor Cell"
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (settings[section].value as! [Setting]).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = (settings[indexPath.section].value as! [Setting])[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: typeOfCell(for: item), for: indexPath)

        cell.textLabel?.text = item.name

        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settings.count == 1 ? "" : settings[section].name
    }
}
