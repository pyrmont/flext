//
//  OptionsViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 4/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

// MARK: - OptionTableViewCell Class

/**
 Represents a table view's cell in the Options section.
 
 The options table view cell contains no additional functionality but is able
 to model the individual elements added in Interface Builder.
 */
class OptionTableViewCell: UITableViewCell {
    
    // MARK: - IB Outlet Values
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var valueTextField: UITextField!
    @IBOutlet var commentLabel: UILabel!
}

// MARK: - OptionsViewController Class

/**
 Displays the Options section.
 
 It is possible for processors in Flext to offer options to a user. This is done
 by the user specifying additional arguments to the `process()` function in the
 underlying JavaScript file.
 */
class OptionsViewController: UIViewController {
    
    // MARK: - IB Outlet Values
    
    @IBOutlet var processorTitle: UINavigationItem!
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Properties
    
    /// The relevant processor.
    var processor: Processor!

    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        processorTitle.title = processor.name
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Listener Setup

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOption(notification:)),
            name: UITextField.textDidChangeNotification,
            object: nil)

        // TODO: Consider whether these listeners can be removed. I don't think they
        // are necessary.
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustTableViewHeight(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustTableViewHeight(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - UI Adjustments

    /**
     Adjusts the table view's height.
     
     - Parameters:
        - notification: The notification of the event that triggered the
                        adjustment.
     */
    @objc func adjustTableViewHeight(notification: Notification) {
        if notification.name == UIResponder.keyboardWillChangeFrameNotification {
            guard let keyboardRect = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            tableView.contentInset.bottom = keyboardRect.cgRectValue.size.height
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            tableView.contentInset.bottom = .zero
        }
    }
    
    // MARK: - Updating
    
    /**
     Updates the value of the option associated with the relevant processor.
     
     Flext takes advantage of classes being reference types to add the updated
     option to `processor`. This object is part of Flext's settings construct.
     By updating the `options` property of `processor`, this will allow a save
     of Flext's settings (implemented separately) to include this new value.
     
     - Parameters:
        - notification: The notification of the event that triggered the update.
     */
    @objc func updateOption(notification: Notification) {
        guard let textField = notification.object as? UITextField else { return }
        guard let indexPath = tableView.indexPathForRow(at: textField.convert(textField.bounds.origin, to: tableView)) else { return }
        
        if let text = textField.text, !text.isEmpty {
            processor.options[indexPath.row].value = text
        } else {
            processor.options[indexPath.row].value = nil
        }
    }

    /**
     Finishes updating the text field.
     
     This method needs to exist so that it is possible to dismiss the modal
     Options section.
     
     - Parameters:
        - sender: The text field that triggered the update.
     */
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
