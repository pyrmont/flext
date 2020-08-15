//
//  ProcessorOptionsViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 4/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class ProcessorOptionTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var valueTextField: UITextField!
    @IBOutlet var commentLabel: UILabel!
}

class ProcessorOptionsViewController: UIViewController {
    @IBOutlet var processorTitle: UINavigationItem!
    @IBOutlet var optionsTable: UITableView!
    @IBOutlet var optionsTableHeight: NSLayoutConstraint!
    
    var processor: Processor!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        processorTitle.title = processor.name
        
        setupListener()
        
        optionsTable.delegate = self
        optionsTable.dataSource = self
    }
    
    func setupListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ProcessorOptionsViewController.updateOption(notification:)),
            name: UITextField.textDidChangeNotification,
            object: nil)
    }
    
    @objc func updateOption(notification: Notification) {
        guard let textField = notification.object as? UITextField else { return }
        guard let cell = textField.superview?.superview as? UITableViewCell else { return }
        guard let indexPath = optionsTable.indexPath(for: cell) else { return }
        
        if let text = textField.text, !text.isEmpty {
            processor.options[indexPath.row].value = text
        } else {
            processor.options[indexPath.row].value = nil
        }
    }
    
    @IBAction func finishUpdating(_ sender: UITextField) { }
}

extension ProcessorOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return processor.options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Option Cell", for: indexPath) as! ProcessorOptionTableViewCell

        cell.nameLabel.text = processor.options[indexPath.row].name.replacingOccurrences(of: "_", with: " ").capitalized

        cell.valueTextField.text = processor.options[indexPath.row].value
        cell.valueTextField.placeholder = processor.options[indexPath.row].defaultValue

        cell.commentLabel.text = processor.options[indexPath.row].comment

        return cell
    }
}
