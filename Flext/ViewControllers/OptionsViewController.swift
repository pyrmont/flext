//
//  OptionsViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 4/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

// MARK: - Option Table View Cell Definition

class OptionTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var valueTextField: UITextField!
    @IBOutlet var commentLabel: UILabel!
}

// MARK: - Option View Controller Definition

class OptionsViewController: UIViewController {
    
    // MARK: - Public Properties
    
    @IBOutlet var processorTitle: UINavigationItem!
    @IBOutlet var tableView: UITableView!
    
    var processor: Processor!

    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        processorTitle.title = processor.name
        
        setupListener()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Listener Setup
    
    func setupListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(OptionsViewController.updateOption(notification:)),
            name: UITextField.textDidChangeNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ManagerViewController.adjustTableViewHeight(notification:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ManagerViewController.adjustTableViewHeight(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    // MARK: - UI Adjustments
    
    @objc func adjustTableViewHeight(notification: Notification) {
        if notification.name == UIResponder.keyboardDidShowNotification {
            guard let keyboardRect = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            tableView.contentInset.bottom = keyboardRect.cgRectValue.size.height
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            tableView.contentInset.bottom = .zero
        }
    }
    
    // MARK: - Updating
    
    @objc func updateOption(notification: Notification) {
        guard let textField = notification.object as? UITextField else { return }
        guard let cell = textField.superview?.superview as? UITableViewCell else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if let text = textField.text, !text.isEmpty {
            processor.options[indexPath.row].value = text
        } else {
            processor.options[indexPath.row].value = nil
        }
    }

    // This is necessary to allow the keyboard to be dismissed when editing the text field
    @IBAction func finishUpdating(_ sender: UITextField) { }
}

// MARK: - Data Source and Delegate

extension OptionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Sections
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: - Rows

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return processor.options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Option Cell", for: indexPath) as! OptionTableViewCell

        cell.nameLabel.text = processor.options[indexPath.row].name.replacingOccurrences(of: "_", with: " ").capitalized

        cell.valueTextField.text = processor.options[indexPath.row].value
        cell.valueTextField.placeholder = processor.options[indexPath.row].defaultValue

        cell.commentLabel.text = processor.options[indexPath.row].comment

        return cell
    }
}
