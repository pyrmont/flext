//
//  SplitProcessorListViewController.swift
//  FlextMac
//
//  Created by Michael Camilleri on 1/9/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import MobileCoreServices

extension Processor {
    var isUserAdded: Bool { type == .userAdded }
}

class SplitProcessorListViewEditableLabel: UITextField {
    override func becomeFirstResponder() -> Bool {
        guard isUserInteractionEnabled else { return false }
        textColor = .label
        backgroundColor = .white
        return super.becomeFirstResponder()
    }

    override func endEditing(_ force: Bool) -> Bool {
        isUserInteractionEnabled = false
        textColor = .white
        backgroundColor = .none
        return super.endEditing(force)
    }
}

class SplitProcessorListViewCell: UITableViewCell {
    // MARK: - IB Outlet Values

    @IBOutlet var titleLabel: SplitProcessorListViewEditableLabel?
}

class SplitProcessorListViewController: UITableViewController {

    // MARK: - Section Enum

    /// A category of processor.
    enum Section: Int {
        case favourited = 0
        case builtIn = 1
        case userAdded = 2
    }

    // MARK: - Properties

    /// The settings for Flext.
    var settings: Settings = SettingsManager.settings

    /// The built-in processors.
    var builtInProcessors: [Processor] = []

    /// The user-added processors.
    var userAddedProcessors: [Processor] = []

    /// The editor view.
    var editor: SplitEditorViewController!

    /// Whether the table has focus.
    var hasFocus = false

    /// Whether a label is being renamed.
    var isRenaming = false

    /// The document picker.
    var documentPicker: UIDocumentPickerViewController!

    // MARK: - IB Outlet Values

    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var removeButton: UIBarButtonItem!
    @IBOutlet var favouriteButton: UIBarButtonItem!
    @IBOutlet var tapRecogniser: UITapGestureRecognizer!

    // MARK: - Controller Loading

    override func viewDidLoad() {
        super.viewDidLoad()

        editor = self.splitViewController?.viewControllers[1] as? SplitEditorViewController

        for processor in settings.processors {
            switch processor.type {
            case .builtIn:
                builtInProcessors.append(processor)
            case .userAdded:
                userAddedProcessors.append(processor)
            }
        }

        let selectedPath = settings.selectedProcessorPath ?? defaultSelectedPath()
        updateSelectedPath(to: selectedPath)

        documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeJavaScript as String], in: .import)
        documentPicker.delegate = self

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @IBAction func handleTaps(_ sender: UITapGestureRecognizer) {
        let existingPath = settings.selectedProcessorPath ?? IndexPath(row: 0, section: 0)

        guard let tappedPath = tableView.indexPathForRow(at: sender.location(in: tableView)) else {
            tableView(tableView, didSelectRowAt: existingPath)
            tableView.becomeFirstResponder()
            return
        }

        guard hasFocus else {
            tableView(tableView, didSelectRowAt: tappedPath)
            tableView.becomeFirstResponder()
            return
        }

        guard tappedPath != existingPath else {
            let cell = tableView.cellForRow(at: tappedPath) as! SplitProcessorListViewCell
            cell.titleLabel?.isUserInteractionEnabled = true
            let _ = cell.titleLabel?.becomeFirstResponder()
            return
        }

        guard let checkedPath = tableView(tableView, willSelectRowAt: tappedPath) else { return }
        guard let deselectingPath = tableView(tableView, willDeselectRowAt: existingPath) else { return }
        tableView(tableView, didDeselectRowAt: deselectingPath)
        tableView(tableView, didSelectRowAt: checkedPath)
        tableView.becomeFirstResponder()
    }

    // MARK: - Selected Path Updating

    func defaultSelectedPath() -> IndexPath {
        if settings.favouritedProcessors.isEmpty {
            return IndexPath(row: 0, section: Section.builtIn.rawValue)
        } else {
            return IndexPath(row: 0, section: Section.favourited.rawValue)
        }
    }

    func updateSelectedPath(to indexPath: IndexPath) {
        var collection: [Processor]
        var sectionIfEmpty: Section
        var rowIfEmpty: Int

        switch Section(rawValue: indexPath.section) {
        case .favourited:
            collection = settings.favouritedProcessors
            sectionIfEmpty = Section.builtIn
            rowIfEmpty = 0
        case .builtIn:
            collection = builtInProcessors
            sectionIfEmpty = Section.builtIn
            rowIfEmpty = 0
        case .userAdded:
            collection = userAddedProcessors
            sectionIfEmpty = Section.builtIn
            rowIfEmpty = builtInProcessors.count - 1
        default:
            return
        }

        if collection.isEmpty {
            settings.selectedProcessorPath = IndexPath(row: rowIfEmpty, section: sectionIfEmpty.rawValue)
        } else {
            var newRow = indexPath.row
            if newRow < 0 {
                newRow = 0
            } else if newRow >= collection.count {
                newRow = collection.count - 1
            }
            settings.selectedProcessorPath = IndexPath(row: newRow, section: indexPath.section)
        }

        tableView.selectRow(at: settings.selectedProcessorPath, animated: false, scrollPosition: .none)

        updateToolbar()

        editor.processor = processor(at: settings.selectedProcessorPath)
        editor.returnToEditor()
    }

    // MARK: - Toolbar Updating

    func updateToolbar() {
        toggleRemoveButton()
        toggleFavouriteButton()
    }

    @IBAction func toggleFavouriteStatus(_ sender: UIBarButtonItem) {
        guard let selectedPath = settings.selectedProcessorPath else { return }
        guard let processor = processor(at: selectedPath) else { return }

        processor.isFavourited.toggle()

        tableView.beginUpdates()

        if processor.isFavourited {
            let rowIndex = settings.favouritedProcessors.count
            settings.favouritedProcessors.append(processor)
            tableView.insertRows(at: [IndexPath(row: rowIndex, section: Section.favourited.rawValue)], with: .automatic)
        } else if let rowIndex = settings.favouritedProcessors.firstIndex(of: processor) {
            settings.favouritedProcessors.remove(at: rowIndex)
            tableView.deleteRows(at: [IndexPath(row: rowIndex, section: Section.favourited.rawValue)], with: .automatic)
        }

        tableView.endUpdates()

        updateSelectedPath(to: selectedPath)
    }

    func toggleRemoveButton() {
        guard let selectedPath = settings.selectedProcessorPath else { return }
        guard let processor = processor(at: selectedPath) else { return }
        removeButton.isEnabled = processor.isUserAdded
    }

    func toggleFavouriteButton() {
        guard let selectedPath = settings.selectedProcessorPath else { return }
        guard let processor = processor(at: selectedPath) else { return }

        let favouriteImage = UIImage(systemName: "heart")
        let unfavouriteImage = UIImage(systemName: "heart.slash")

        if processor.isFavourited {
            favouriteButton.image = unfavouriteImage
        } else {
            favouriteButton.image = favouriteImage
        }
    }

    // MARK: - Moving

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.favourited.rawValue ? true : false
    }

    // There is a bug (I think here) where sometimes the move doesn't happen. I don't know why.
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard sourceIndexPath.section == Section.favourited.rawValue else { return sourceIndexPath }

        if proposedDestinationIndexPath.section != Section.favourited.rawValue {
            let lastRowIndex = self.tableView(tableView, numberOfRowsInSection: sourceIndexPath.section) - 1
            return IndexPath(row: lastRowIndex, section: sourceIndexPath.section)
        } else {
            return proposedDestinationIndexPath
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let processor = settings.favouritedProcessors.remove(at: sourceIndexPath.row)
        settings.favouritedProcessors.insert(processor, at: destinationIndexPath.row)

        editor.savePreferences()

        guard let selectedPath = settings.selectedProcessorPath else { return }
        guard selectedPath.section == Section.favourited.rawValue else { return }
        if selectedPath.row == sourceIndexPath.row {
            settings.selectedProcessorPath?.row = destinationIndexPath.row
        } else if selectedPath.row > sourceIndexPath.row && selectedPath.row <= destinationIndexPath.row {
            settings.selectedProcessorPath?.row -= 1
        } else if selectedPath.row < sourceIndexPath.row && selectedPath.row >= destinationIndexPath.row {
            settings.selectedProcessorPath?.row += 1
        }
    }


    // MARK: - Inserting

    @IBAction func insertProcessor(_ sender: UIBarButtonItem) {
        present(documentPicker, animated: true, completion: nil)
    }

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

        let userAddedIndexPath = IndexPath(row: userAddedProcessors.count - 1, section: Section.userAdded.rawValue)

        tableView.beginUpdates()

        if userAddedIndexPath.row == 0 {
            tableView.insertSections([Section.userAdded.rawValue], with: .automatic)
        } else {
            tableView.insertRows(at: [userAddedIndexPath], with: .automatic)
        }

        tableView.endUpdates()

        updateSelectedPath(to: userAddedIndexPath)
    }

    // MARK: - Removing

    @IBAction func removeProcessor(_ sender: UIBarButtonItem) {
        guard let selectedPath = settings.selectedProcessorPath else { return }
        guard let processor = processor(at: selectedPath) else { return }
        guard processor.isUserAdded else { return }
        removeProcessor(at: selectedPath)
    }

    func removeProcessor(at indexPath: IndexPath) {
        guard let processor = processor(at: indexPath) else { return }

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

        tableView.beginUpdates()

        if let userAddedIndex = userAddedProcessors.firstIndex(of: processor) {
            userAddedProcessors.remove(at: userAddedIndex)
            if userAddedProcessors.isEmpty {
                tableView.deleteSections([Section.userAdded.rawValue], with: .automatic)
            } else {
                tableView.deleteRows(at: [IndexPath(row: userAddedIndex, section: Section.userAdded.rawValue)], with: .automatic)
            }
        }


        if let favouriteIndex = settings.favouritedProcessors.firstIndex(of: processor) {
            tableView.deleteRows(at: [IndexPath(row: favouriteIndex, section: Section.favourited.rawValue)], with: .automatic)
        }

        settings.remove(processor)

        tableView.endUpdates()

        updateSelectedPath(to: indexPath)
    }

    // MARK: - Table Methods

    func processor(at indexPath: IndexPath?) -> Processor? {
        guard let indexPath = indexPath else { return nil }

        switch Section(rawValue: indexPath.section) {
        case .favourited:
            return settings.favouritedProcessors.at(indexPath.row)
        case .builtIn:
            return builtInProcessors.at(indexPath.row)
        case .userAdded:
            return userAddedProcessors.at(indexPath.row)
        default:
            return nil
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return userAddedProcessors.isEmpty ? 2 : 3
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .favourited:
            return "Favourites"
        case .builtIn:
            return "Built-In Processors"
        case .userAdded:
            return "User-Added Processors"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .favourited:
            return settings.favouritedProcessors.count
        case .builtIn:
            return builtInProcessors.count
        case .userAdded:
            return userAddedProcessors.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let processor = processor(at: indexPath) else { return UITableViewCell() }

        let identifier = processor.hasOptions ? "Processor (Options)" : "Processor"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        if let customCell = cell as? SplitProcessorListViewCell {
            customCell.titleLabel?.text = processor.name
        }
//        cell.textLabel?.text = processor.name

        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard processor(at: indexPath) != nil else { return nil }

        return indexPath
    }

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard hasFocus else { return }
        let cell = tableView.cellForRow(at: indexPath) as? SplitProcessorListViewCell
        cell?.titleLabel?.textColor = .white
        cell?.tintColor = .white
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let existingPath = settings.selectedProcessorPath else { return true }
        guard indexPath != existingPath else { return true }
        let cell = tableView.cellForRow(at: existingPath) as? SplitProcessorListViewCell
        cell?.titleLabel?.textColor = .label
        cell?.tintColor = .label
        return true
    }

//    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath) as? SplitProcessorListViewCell
//        cell?.titleLabel?.textColor = .label
//        cell?.tintColor = .label
//    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? SplitProcessorListViewCell
        cell?.titleLabel?.textColor = .white
        cell?.tintColor = .white

        updateSelectedPath(to: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? SplitProcessorListViewCell
        cell?.titleLabel?.textColor = .label
        cell?.tintColor = .label
    }

    override func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let tableHasFocus = context.nextFocusedView?.isDescendant(of: tableView) else { return }
        guard let existingPath = settings.selectedProcessorPath else { return }
        guard let cell = tableView.cellForRow(at: existingPath) as? SplitProcessorListViewCell else { return }

        if tableHasFocus {
            cell.titleLabel?.textColor = .white
            cell.tintColor = .white
            hasFocus = true
        } else {
            let _ = cell.titleLabel?.endEditing(true)
            cell.titleLabel?.textColor = .label
            cell.tintColor = .label
            hasFocus = false
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        // Load and configure your view controller.
        let storyboard = UIStoryboard(name: "MainMac", bundle: nil)
        guard let optionsVC = storyboard.instantiateViewController(withIdentifier: "Options") as? SplitOptionsViewController else { return }

        optionsVC.processor = processor(at: indexPath)
        optionsVC.editor = editor

        // Use the popover presentation style for your view controller.
        optionsVC.modalPresentationStyle = .popover
        optionsVC.popoverPresentationController?.permittedArrowDirections = .left

        // Specify the anchor point for the popover.
        optionsVC.popoverPresentationController?.sourceView = cell
        optionsVC.popoverPresentationController?.sourceRect = CGRect(x: cell.bounds.maxX + 5, y: cell.bounds.midY, width: 0, height: 0)

        optionsVC.preferredContentSize = CGSize(width: 300, height: optionsVC.processor.options.count * 140)

        // Present the view controller (in a popover).
        self.present(optionsVC, animated: true, completion: nil)
    }
}

// MARK: - Document Picker

extension SplitProcessorListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            insertProcessor(with: url)
        }
    }
}
