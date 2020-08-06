//
//  ProcessorOptionsViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 4/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class ProcessorOptionTableViewCell: UITableViewCell {
    @IBOutlet var parameterName: UILabel!
    @IBOutlet var defaultValue: UITextField!
    @IBOutlet var comment: UILabel!
}

class ProcessorOptionsViewController: UIViewController {
    @IBOutlet var processorTitle: UINavigationItem!
    @IBOutlet var optionsTable: UITableView!
    @IBOutlet var optionsTableHeight: NSLayoutConstraint!
    
    var processor: ProcessorModel!
    var options: [ProcessorOption] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        processorTitle.title = processor.name
        options = processor.options
        
        optionsTable.delegate = self
        optionsTable.dataSource = self
        optionsTable.rowHeight = UITableView.automaticDimension
        optionsTable.estimatedRowHeight = 100
    }
    
    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        optionsTableHeight.constant = optionsTable.contentSize.height
    }
}

extension ProcessorOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Option Cell", for: indexPath) as! ProcessorOptionTableViewCell

        cell.parameterName.text = options[indexPath.row].name.replacingOccurrences(of: "_", with: " ").capitalized
        cell.defaultValue.placeholder = options[indexPath.row].defaultValue
        cell.comment.text = options[indexPath.row].comment

        return cell
    }
}
