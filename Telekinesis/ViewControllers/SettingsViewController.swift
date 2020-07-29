//
//  SettingsViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 29/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

struct SettingSection {
    var name: String
    var items: [SettingItem]
}

protocol SettingItem {
    var name: String { get }
    var cellType: String { get }
}

extension ProcessorModel: SettingItem {
    var cellType: String {
        get { "Selectable Cell" }
    }
}

extension String: SettingItem  {
    var name: String {
        get { self }
    }
    
    var cellType: String {
        get { "Disclosable Cell" }
    }
}

class SettingsViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeight: NSLayoutConstraint!
    
    var settings: [SettingSection]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        settings = [SettingSection]()
        
        if let processorFileURLs = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "Processors") {
            settings.append(SettingSection(
                name: "Processors",
                items: processorFileURLs.map { ProcessorModel(path: $0 )}))
        }
        
        settings.append(SettingSection(name: "Other", items: ["About"]))
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        tableViewHeight.constant = tableView.contentSize.height
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = settings[indexPath.section].items[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: item.cellType, for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = item.name

        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settings[section].name
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
