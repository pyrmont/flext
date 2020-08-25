//
//  ManagerViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 9/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore
import MobileCoreServices

// MARK: - Manager Text Field Definition

class ManagerTextField: UITextField {
    weak var containingCell: ManagerTableViewCell!
}

// MARK: - Manager Table View Cell Definition

class ManagerTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var enabledToggle: UISwitch?
    @IBOutlet var textField: UITextField?
    
    weak var processor: Processor!
    
    func set(text: String) {
        titleLabel?.text = text
        textField?.text = text
    }
}

// MARK: - Manager View Controller Definition

class ManagerViewController: UIViewController {
    typealias Section = Settings.Section
    
    // MARK: Public Properties
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var removeButton: UIBarButtonItem!

    var settings: Settings = SettingsManager.settings
    
    var builtInProcessors: [Processor] = []
    var userAddedProcessors: [Processor] = []
    
    var documentPicker: UIDocumentPickerViewController!
    
    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupListeners()
        
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
    
    func setupListeners() {
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
    
    // MARK: Editing Mode
    
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
    
    @IBAction func enableProcessor(_ sender: UISwitch) {
        guard let cell = sender.superview?.superview as? ManagerTableViewCell else { return }
        
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
    
    @IBAction func finishedRenaming(_ sender: ManagerTextField) {
        guard let text = sender.text else { return }
        guard !text.isEmpty else { return }

        guard let cell = sender.containingCell else { return }
        cell.processor.name = text
        
        guard let enabledRow = settings.enabledProcessors.firstIndex(of: cell.processor) else { return }
        guard let enabledCell = tableView.cellForRow(at: IndexPath(row: enabledRow, section: Section.enabled.rawValue)) as? ManagerTableViewCell else { return }
        enabledCell.set(text: text)
    }
    
    // MARK: Adding Files
    
    @IBAction func openDocumentPicker(_ sender: UIBarButtonItem) {
        present(documentPicker, animated: true, completion: nil)
    }

    func addFile(at url: URL) throws -> URL? {
        var importURL: URL? = nil
        var importError: FlextError? = nil

        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, options: [.withoutChanges], error: &error) { (url) in
            do {
                guard let jsContext = JSContext() else { throw FlextError(type: .failedToLoadJSContext) }
                guard let jsSource = try? String(contentsOf: url) else { throw FlextError(type: .failedToReadFile) }
                jsContext.evaluateScript(jsSource)
                guard let jsValue = jsContext.objectForKeyedSubscript("process") else { throw FlextError(type: .failedToEvaluateJavaScript) }
                guard !jsValue.isUndefined else { throw FlextError(type: .failedToFindProcessFunction) }
                guard let appDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.inqk.Flext") else { throw FlextError(type: .failedToLoadPath) }

                importURL = URL(fileURLWithPath: UUID().uuidString + "." + url.pathExtension, isDirectory: false, relativeTo: appDirectory)
                try FileManager.default.copyItem(at: url, to: importURL!)
            } catch let error as FlextError {
                importError = error.with(location: (#file, #line))
            } catch let error as NSError where error.code == NSFileWriteFileExistsError {
                importError = FlextError(type: .failedToCopyFile, location: (#file, #line))
            } catch {
                importError = FlextError(type: .unknown, location: (#file, #line))
            }
        }
        
        guard importError == nil else { throw importError! }
        
        return importURL
    }
    
    // MARK: - Removing Files
    
    func removeFile(at url: URL) throws {
        var deleteError: FlextError? = nil

        var error: NSError? = nil
        NSFileCoordinator().coordinate(writingItemAt: url, options: [.forDeleting], error: &error) { (url) in
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError where error.code == NSFileWriteFileExistsError {
                deleteError = FlextError(type: .failedToDeleteFile, location: (#file, #line))
            } catch {
                deleteError = FlextError(type: .unknown, location: (#file, #line))
            }
        }
        
        guard deleteError == nil else { throw deleteError! }
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
            (cell.textField! as! ManagerTextField).containingCell = cell
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
    
    func insertProcessor(with url: URL) {
        var processor: Processor
        
        do {
            let filePath = try addFile(at: url)
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
            try removeFile(at: processor.path)
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
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        insertProcessor(with: url)
    }
}
