//
//  ManagerViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 9/8/20.
//  Copyright © 2021 Michael Camilleri. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0.

import UIKit
import MobileCoreServices

// MARK: - ManagerTableViewCell Class

/**
 Represents a table view's cell in the Manager section.

 Elements of a cell in the Manager's `UITableView` need to be capable of being
 updated in response to the user interacting with other table cells. This class
 provides references to these elements that the controller can easily access.
 */
class ManagerTableViewCell: UITableViewCell {

    // MARK: - IB Outlet Values

    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var enabledToggle: UISwitch?
    @IBOutlet var textField: UITextField?

    // MARK: - Properties

    /// The associated processor.
    weak var processor: Processor!

    // MARK: - Text Setting

    /**
     Sets the text to display.

     The `ManagerTableViewCell` displays a `ManagerTextField` object in place
     of the typical `UILabel`. However, since `ManagerTableViewCell` is a
     subclass of `UITableViewCell`, a `UILabel` is nevertheless included as
     part of the class structure. For accessibility reasons, this method sets
     the value of both the objects to 'display' the same text.`

     - Parameters:
        - text: The text to display (this should be the name of the relevant
                processor).
     */
    func set(text: String) {
        titleLabel?.text = text
        textField?.text = text
    }
}

// MARK: - ManagerViewController Class

/**
 Displays the Manager section.

 Flext allows the user to add, remove, enable, disable and reorder its
 processors. This is achieved through the Manager section of the app. This view
 controller is responsible for displaying that section and handling the logic
 associated with the user's changes.

 While UITableView provides native reordering functionality of the rows in the
 table, Flext uses UIKit's drag and drop functions to implement reordering. This
 is because only one section of the processors (the array of enabled processors)
 can be reordered.
 */
class ManagerViewController: UIViewController {

    // MARK: - Type Aliases

    /// A category of processor.
    typealias Section = Settings.Section

    // MARK: - IB Outlet Values

    @IBOutlet var tableView: UITableView!
    @IBOutlet var removeButton: UIBarButtonItem!

    // MARK: - Properties

    /// The settings for Flext.
    var settings: Settings = SettingsManager.settings

    /// The built-in processors.
    var builtInProcessors: [Processor] = []

    /// The user-added processors.
    var userAddedProcessors: [Processor] = []

    /// The document picker.
    var documentPicker: UIDocumentPickerViewController!

    // MARK: - Controller Loading

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

        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self

        // This is a means of adjusting the duration the user has to wait before
        // drag and drop becomes active.
        if let recognizers = tableView.gestureRecognizers {
            for case let recognizer as UILongPressGestureRecognizer in recognizers {
                recognizer.minimumPressDuration = 0.2
            }
        }

        removeButton.isEnabled = !userAddedProcessors.isEmpty

        documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeJavaScript as String], in: .import)
        documentPicker.delegate = self
    }

    // MARK: - Listener Setup

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: Editing Mode

    /**
     Toggles whether the table is in editing mode.

     This method toggles whether the table is in editing mode or not. If so, it
     scrolls the view to the user-added section (as this is the only section
     from which processors can be added or removed).

     - parameters:
        - sender: The button that triggered the toggling.
     */
    @IBAction func toggleEditing(_ sender: UIBarButtonItem) {
        if tableView.isEditing {
            removeButton.title = "Remove"
            tableView.setEditing(false, animated: true)
        } else {
            removeButton.title = "Done"
            tableView.setEditing(true, animated: true)
            tableView.scrollToRow(at: IndexPath(row: 0, section: Section.userAdded.rawValue), at: .top, animated: true)
        }
    }

    // MARK: - Enabling Processors

    /**
     Enables a processor.

     Flext does not permit a user to remove the built-in processors. A user may
     nevertheless have no interest in a particular processor and not want to use
     it. Flext's solution is to allow the user to disable processors.

     This method ensures that at least one active processor is enabled. It does
     this by looping through the cells that are visible and toggling their
     enabled status. This loop will also _reenable_ disabling if the second
     of final two processors is _enabled_.

     - Parameters:
        - sender: The switch that triggered the toggle.
     */
    @IBAction func enableProcessor(_ sender: UISwitch) {
        let pointInTable = sender.convert(sender.bounds.origin, to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: pointInTable) else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? ManagerTableViewCell else { return }

        cell.processor.isEnabled = sender.isOn

        if sender.isOn {
            let rowIndex = settings.enabledProcessors.count
            settings.enabledProcessors.append(cell.processor)
            tableView.insertRows(at: [IndexPath(row: rowIndex, section: Section.enabled.rawValue)], with: .automatic)
        } else {
            guard let rowIndex = settings.enabledProcessors.firstIndex(of: cell.processor) else { return }
            settings.enabledProcessors.remove(at: rowIndex)
            tableView.deleteRows(at: [IndexPath(row: rowIndex, section: Section.enabled.rawValue)], with: .automatic)
            if settings.selectedProcessorPath?.row == rowIndex {
                settings.resetSelectedProcessor()
            }
        }

        for cell in tableView.visibleCells {
            guard let toggle = (cell as! ManagerTableViewCell).enabledToggle else { continue }
            toggle.isEnabled = settings.enabledProcessors.count == 1 ? !toggle.isOn : true
        }
    }

    // MARK: Renaming Processors

    /**
     Finishes renaming the processor.

     - Parameters:
        - sender: The text field for the processor being renamed.
     */
    @IBAction func finishedRenaming(_ sender: UITextField) {
        guard let text = sender.text else { return }
        guard !text.isEmpty else { return }

        guard let indexPath = tableView.indexPathForRow(at: sender.convert(sender.bounds.origin, to: tableView)) else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? ManagerTableViewCell else { return }
        cell.processor.name = text

        guard let enabledRow = settings.enabledProcessors.firstIndex(of: cell.processor) else { return }
        guard let enabledCell = tableView.cellForRow(at: IndexPath(row: enabledRow, section: Section.enabled.rawValue)) as? ManagerTableViewCell else { return }
        enabledCell.set(text: text)
    }

    // MARK: Adding Files

    /**
     Opens the document picker.

     - Parameters:
        - sender: The button that will trigger the document picker to be opened.
     */
    @IBAction func openDocumentPicker(_ sender: UIBarButtonItem) {
        present(documentPicker, animated: true, completion: nil)
    }

    // MARK: - UI Adjustments

    /**
     Adjusts the table view's height.

     This method is necessary to ensure that the table view is not hidden behind
     the keyboard when a value is being edited.

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let footerView = tableView.tableFooterView else {
            return
        }

        let width = tableView.bounds.size.width
        let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))

        if footerView.frame.size.height != size.height {
            footerView.frame.size.height = size.height
            tableView.tableFooterView = footerView
        }
    }
}

// MARK: - Data Source and Delegate

extension ManagerViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Sections

    func numberOfSections(in tableView: UITableView) -> Int {
        return userAddedProcessors.isEmpty ? 2 : 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .enabled:
            return "Ordering"
        case .builtIn:
            return "Built-In Processors"
        case .userAdded:
            return "User-Added Processors"
        default:
            return nil
        }
    }

    // MARK: - Rows

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .enabled:
            return settings.enabledProcessors.count
        case .builtIn:
            return builtInProcessors.count
        case .userAdded:
            return userAddedProcessors.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var processor: Processor
        var cell: ManagerTableViewCell

        switch Section(rawValue: indexPath.section) {
        case .enabled:
            processor = settings.enabledProcessors[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "Reordering Cell", for: indexPath) as! ManagerTableViewCell
            cell.titleLabel!.text = processor.name
        case .builtIn:
            processor = builtInProcessors[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "Enabling Cell", for: indexPath) as! ManagerTableViewCell
            cell.textField!.text = processor.name
            cell.textField!.isEnabled = false
            cell.enabledToggle!.isOn = processor.isEnabled
            cell.enabledToggle!.isEnabled = settings.enabledProcessors.count == 1 ? !cell.enabledToggle!.isOn : true
        case .userAdded:
            processor = userAddedProcessors[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "Enabling Cell", for: indexPath) as! ManagerTableViewCell
            cell.textField!.text = processor.name
            cell.textField!.delegate = self
            cell.enabledToggle!.isOn = processor.isEnabled
            cell.enabledToggle!.isEnabled = settings.enabledProcessors.count == 1 ? !cell.enabledToggle!.isOn : true
        default:
            return UITableViewCell()
        }

        cell.processor = processor

        return cell
    }

    // MARK: - Editing

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.userAdded.rawValue ? true : false
    }

    // MARK: - Moving

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.enabled.rawValue ? true : false
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard sourceIndexPath.section == Section.enabled.rawValue else { return sourceIndexPath }

        if proposedDestinationIndexPath.section != Section.enabled.rawValue {
            let lastRowIndex = self.tableView(tableView, numberOfRowsInSection: sourceIndexPath.section) - 1
            return IndexPath(row: lastRowIndex, section: sourceIndexPath.section)
        } else {
            return proposedDestinationIndexPath
        }
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let processor = settings.enabledProcessors.remove(at: sourceIndexPath.row)
        settings.enabledProcessors.insert(processor, at: destinationIndexPath.row)

        guard let selectedPath = settings.selectedProcessorPath else { return }
        if selectedPath.row == sourceIndexPath.row {
            settings.selectedProcessorPath?.row = destinationIndexPath.row
        } else if selectedPath.row > sourceIndexPath.row && selectedPath.row <= destinationIndexPath.row {
            settings.selectedProcessorPath?.row -= 1
        } else if selectedPath.row < sourceIndexPath.row && selectedPath.row >= destinationIndexPath.row {
            settings.selectedProcessorPath?.row += 1
        }
    }

    // MARK: - Inserting

    /**
     Inserts the processor.

     This method attempts to insert a processor into the collection of
     processors managed by Flext. If that fails, the method displays an alert to
     the user giving an explanation of what went wrong.

     Assuming that it is successful, the method then inserts the newly
     added processor into the correct sections of the table, refreshes the table
     view and then scrolls the table to the row that has been added.

     - Parameters:
        - url: The URL of the file to be inserted.
     */
    func insertProcessor(with url: URL) {
        var processor: Processor

        do {
            let filePath = try FileHandler.addFile(at: url)
            let name = url.deletingPathExtension().lastPathComponent
            processor = try Processor(path: filePath!, type: .userAdded, name: name)
        } catch {
            guard let error = error as? FlextError else { return }

            let alert = UIAlertController(title: "Import Failed", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default) { _ in
                NSLog(error.logMessage)
            })
            self.present(alert, animated: true, completion: nil)

            return
        }

        userAddedProcessors.append(processor)
        settings.add(processor)

        let enabledIndexPath = IndexPath(row: settings.enabledProcessors.count - 1, section: Section.enabled.rawValue)
        let userAddedIndexPath = IndexPath(row: userAddedProcessors.count - 1, section: Section.userAdded.rawValue)

        tableView.beginUpdates()

        tableView.insertRows(at: [enabledIndexPath], with: .automatic)
        if userAddedIndexPath.row == 0 {
            tableView.insertSections([Section.userAdded.rawValue], with: .automatic)
            removeButton.isEnabled = true
        } else {
            tableView.insertRows(at: [userAddedIndexPath], with: .automatic)
        }

        tableView.endUpdates()
        tableView.scrollToRow(at: userAddedIndexPath, at: .top, animated: true)
    }

    // MARK: - Deleting

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        guard let processor = userAddedProcessors.at(indexPath.row) else { return }

        do {
            try FileHandler.removeFile(at: processor.path)
        } catch {
            guard let error = error as? FlextError else { return }

            let alert = UIAlertController(title: "Removal Failed", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default) { _ in
                NSLog(error.logMessage)
            })
            self.present(alert, animated: true, completion: nil)

            return
        }

        userAddedProcessors.remove(at: indexPath.row)

        tableView.beginUpdates()

        if userAddedProcessors.isEmpty {
            tableView.deleteSections([Section.userAdded.rawValue], with: .automatic)
            removeButton.isEnabled = false
            toggleEditing(removeButton)
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        let enabledIndexPath = settings.enabledProcessors.firstIndex(of: processor)
        settings.remove(processor)
        if enabledIndexPath != nil {
            tableView.deleteRows(at: [IndexPath(row: enabledIndexPath!, section: Section.enabled.rawValue)], with: .automatic)
        }

        tableView.endUpdates()
    }
}

// MARK: - Dragging and Dropping

extension ManagerViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.section == Section.enabled.rawValue else { return [] }
        return [UIDragItem(itemProvider: NSItemProvider())]
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard session.localDragSession != nil else { return UITableViewDropProposal(operation: .cancel, intent: .unspecified) }

        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }

    func tableView(_ tableView: UITableView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }
}

// MARK: - Text Field

extension ManagerViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return false }
        guard !text.isEmpty else { return false }
        return true
    }
}

// MARK: - Document Picker

extension ManagerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            insertProcessor(with: url)
        }
    }
}
