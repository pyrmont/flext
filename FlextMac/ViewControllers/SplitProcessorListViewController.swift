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

    /// The document picker.
    var documentPicker: UIDocumentPickerViewController!

    // MARK: - IB Outlet Values

    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var removeButton: UIBarButtonItem!
    @IBOutlet var favouriteButton: UIBarButtonItem!

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

    // MARK: - Selected Path Updating

    func defaultSelectedPath() -> IndexPath {
        if settings.favouritedProcessors.isEmpty {
            return IndexPath(row: 0, section: Section.builtIn.rawValue)
        } else {
            return IndexPath(row: 0, section: Section.favourited.rawValue)
        }
    }

    func updateSelectedPath(to indexPath: IndexPath, plus increase: Int = 0, minus decrease: Int = 0) {
        let change = increase - decrease
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
            settings.selectedProcessorPath = IndexPath(row: indexPath.row + change, section: indexPath.section)
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
            if selectedPath.section == Section.favourited.rawValue && selectedPath.row == rowIndex {
                updateSelectedPath(to: selectedPath, minus: 1)
            }
        }

        tableView.endUpdates()

        toggleFavouriteButton()

        editor.savePreferences()
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
        print("Removing...")
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

        updateSelectedPath(to: indexPath, minus: 1)
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
        cell.textLabel?.text = processor.name

        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let _ = processor(at: indexPath) else { return nil }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard hasFocus else { return }
        let cell = tableView.cellForRow(at: indexPath)
        cell?.tintColor = .white
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let selectedPath = tableView.indexPathForSelectedRow else { return true }
        guard indexPath != selectedPath else { return true }
        let cell = tableView.cellForRow(at: selectedPath)
        cell?.tintColor = .label
        return true
    }

    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.tintColor = .label
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.tintColor = .white

        updateSelectedPath(to: indexPath)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.tintColor = .label
    }

    override func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let selectedPath = tableView.indexPathForSelectedRow else { return }
        guard let cell = tableView.cellForRow(at: selectedPath) else { return }
        if context.nextFocusedIndexPath == nil {
            cell.tintColor = .label
            hasFocus = false
        } else {
            cell.tintColor = .white
            hasFocus = true
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        // Load and configure your view controller.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
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