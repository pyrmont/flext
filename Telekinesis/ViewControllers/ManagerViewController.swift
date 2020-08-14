//
//  ManagerViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 9/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore
import MobileCoreServices

class ManagerTextField: UITextField {
    weak var containingCell: ManagerTableViewCell!
}

class ManagerTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var enabledToggle: UISwitch?
    @IBOutlet var textField: UITextField?
    
    weak var processor: ProcessorModel!
    
    func set(text: String) {
        titleLabel?.text = text
        textField?.text = text
    }
}

class ManagerViewController: UIViewController {
    enum Section: Int {
        case enabled
        case builtIn
        case userAdded
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var editingButton: UIBarButtonItem!
    
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
    
    @IBAction func finishedRelabelling(_ sender: ManagerTextField) {
        guard let text = sender.text else { return }
        guard !text.isEmpty else { return }

        guard let cell = sender.containingCell else { return }
        cell.processor.name = text
        
        guard let enabledRow = settings.enabledProcessors.firstIndex(of: cell.processor) else { return }
        guard let enabledCell = tableView.cellForRow(at: IndexPath(row: enabledRow, section: Section.enabled.rawValue)) as? ManagerTableViewCell else { return }
        enabledCell.set(text: text)
    }
    
    @IBAction func openDocumentPicker(_ sender: UIBarButtonItem) {
        present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func enableEditing(_ sender: UIBarButtonItem) {
        if tableView.isEditing {
            editingButton.title = "Remove"
            tableView.setEditing(false, animated: true)
        } else {
            editingButton.title = "Done"
            tableView.setEditing(true, animated: true)
            tableView.scrollToRow(at: IndexPath(row: 0, section: Section.userAdded.rawValue), at: .top, animated: true)
        }
    }
    
    var settings: SettingsModel!
    var builtInProcessors: [ProcessorModel] = []
    var userAddedProcessors: [ProcessorModel] = []
    
    var documentPicker: UIDocumentPickerViewController!
    var appDocumentsDirectory: URL!
    
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

        documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeJavaScript as String], in: .import)
        documentPicker.delegate = self
        
        appDocumentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let editor = segue.destination as? EditorViewController else { return }
        editor.setupProcessor(using: settings.selectedProcessor!)
        editor.runProcessor()
    }
    
    func setupListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ManagerViewController.adjustTextEditorHeight(notification:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ManagerViewController.adjustTextEditorHeight(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    @objc func adjustTextEditorHeight(notification: Notification) {
        if notification.name == UIResponder.keyboardDidShowNotification {
            guard let keyboardRect = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardRect.cgRectValue.size.height, right: 0.0)
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            tableView.contentInset = .zero
        }
    }
    
    func addFile(at url: URL) throws -> URL? {
        var importURL: URL? = nil
        var importError: TelekinesisError? = nil

        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, options: [.withoutChanges], error: &error) { (url) in
            do {
                guard let jsContext = JSContext() else { throw TelekinesisError(type: .failedToLoadJSContext) }
                guard let jsSource = try? String(contentsOf: url) else { throw TelekinesisError(type: .failedToReadFile) }
                jsContext.evaluateScript(jsSource)
                guard let jsValue = jsContext.objectForKeyedSubscript("process") else { throw TelekinesisError(type: .failedToEvaluateJavaScript) }
                guard !jsValue.isUndefined else { throw TelekinesisError(type: .failedToFindProcessFunction) }

                importURL = URL(fileURLWithPath: UUID().uuidString + "." + url.pathExtension, isDirectory: false, relativeTo: appDocumentsDirectory)
                try FileManager.default.copyItem(at: url, to: importURL!)
            } catch let error as TelekinesisError {
                importError = error.with(location: (#file, #line))
            } catch let error as NSError where error.code == NSFileWriteFileExistsError {
                importError = TelekinesisError(type: .failedToCopyFile, location: (#file, #line))
            } catch {
                importError = TelekinesisError(type: .unknown, location: (#file, #line))
            }
        }
        
        guard importError == nil else { throw importError! }
        
        return importURL
    }
    
    func removeFile(at url: URL) throws {
        var deleteError: TelekinesisError? = nil

        var error: NSError? = nil
        NSFileCoordinator().coordinate(writingItemAt: url, options: [.forDeleting], error: &error) { (url) in
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError where error.code == NSFileWriteFileExistsError {
                deleteError = TelekinesisError(type: .failedToDeleteFile, location: (#file, #line))
            } catch {
                deleteError = TelekinesisError(type: .unknown, location: (#file, #line))
            }
        }
        
        guard deleteError == nil else { throw deleteError! }
    }
}

extension ManagerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return userAddedProcessors.isEmpty ? 2 : 3
    }
    
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var processor: ProcessorModel
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.userAdded.rawValue ? true : false
    }
    
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
   
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        guard let processor = userAddedProcessors.at(indexPath.row) else { return }
        
        do {
            try removeFile(at: processor.path)
        } catch {
            guard let error = error as? TelekinesisError else { return }
            
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
            tableView.deleteSections([indexPath.section], with: .automatic)
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

extension ManagerViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return false }
        guard !text.isEmpty else { return false }
        return true
    }
}
    
extension ManagerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        var filePath: URL?
        
        do {
            filePath = try addFile(at: url)
        } catch {
            guard let error = error as? TelekinesisError else { return }
            
            let alert = UIAlertController(title: "Import Failed", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default) { _ in
                NSLog(error.logMessage)
            })
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        guard filePath != nil else { return }
        let name = url.deletingPathExtension().lastPathComponent
        guard let processor = try? ProcessorModel(path: filePath!, type: .userAdded, name: name) else { return }
        
        userAddedProcessors.append(processor)
        settings.add(processor)
        
        let enabledIndexPath = IndexPath(row: settings.enabledProcessors.count - 1, section: Section.enabled.rawValue)
        let userAddedIndexPath = IndexPath(row: userAddedProcessors.count - 1, section: Section.userAdded.rawValue)
        
        tableView.beginUpdates()
        
        tableView.insertRows(at: [enabledIndexPath], with: .automatic)
        if userAddedIndexPath.row == 0 {
            tableView.insertSections([2], with: .automatic)
        } else {
            tableView.insertRows(at: [userAddedIndexPath], with: .automatic)
        }
        
        tableView.endUpdates()
        tableView.scrollToRow(at: userAddedIndexPath, at: .top, animated: true)
    }
}
