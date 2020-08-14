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

class ManagerTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var enabledToggle: UISwitch?
    
    weak var processor: ProcessorModel!
}

class ManagerViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var editingButton: UIBarButtonItem!
    
    @IBAction func enableProcessor(_ sender: UISwitch) {
        guard let cell = sender.superview?.superview as? ManagerTableViewCell else { return }
        
        cell.processor.isEnabled = sender.isOn
        
        if sender.isOn {
            let rowIndex = settings.enabledProcessors.count
            settings.enabledProcessors.append(cell.processor)
            tableView.insertRows(at: [IndexPath(row: rowIndex, section: 0)], with: .automatic)
        } else {
            guard let rowIndex = settings.enabledProcessors.firstIndex(of: cell.processor) else { return }
            settings.enabledProcessors.remove(at: rowIndex)
            tableView.deleteRows(at: [IndexPath(row: rowIndex, section: 0)], with: .automatic)
            if settings.selectedProcessorPath?.row == rowIndex {
                settings.resetSelectedProcessor()
            }
        }
            
        for cell in tableView.visibleCells {
            guard let toggle = (cell as! ManagerTableViewCell).enabledToggle else { continue }
            toggle.isEnabled = settings.enabledProcessors.count == 1 ? !toggle.isOn : true
        }
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
            tableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .top, animated: true)
        }
    }
    
    var settings: SettingsModel!
    var builtInProcessors: [ProcessorModel] = []
    var userAddedProcessors: [ProcessorModel] = []
    
    var documentPicker: UIDocumentPickerViewController!
    var appDocumentsDirectory: URL!
    
    var leadingActions: UISwipeActionsConfiguration!
    
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
        
        if let recognizers = tableView.gestureRecognizers {
            for case let recognizer as UILongPressGestureRecognizer in recognizers {
                recognizer.minimumPressDuration = 0.2
            }
        }

        documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeJavaScript as String], in: .import)
        documentPicker.delegate = self
        
        appDocumentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        leadingActions = UISwipeActionsConfiguration(actions: [UIContextualAction(style: .normal, title: "Edit", handler: {_,_,_ in
            print("Edit")
        })])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let editor = segue.destination as? EditorViewController else { return }
        editor.setupProcessor(using: settings.selectedProcessor!)
        editor.runProcessor()
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

                importURL = URL(fileURLWithPath: url.lastPathComponent, isDirectory: false, relativeTo: appDocumentsDirectory)
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
        switch section {
        case 1:
            return builtInProcessors.count
        case 2:
            return userAddedProcessors.count
        default:
            return settings.enabledProcessors.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Built-In Processors"
        case 2:
            return "User-Added Processors"
        default:
            return "Ordering"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var processor: ProcessorModel
        var cellID: String
        
        switch indexPath.section {
        case 1:
            processor = builtInProcessors[indexPath.row]
            cellID = "Enabling Cell"
        case 2:
            processor = userAddedProcessors[indexPath.row]
            cellID = "Enabling Cell"
        default:
            processor = settings.enabledProcessors[indexPath.row]
            cellID = "Reordering Cell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! ManagerTableViewCell
        
        cell.titleLabel?.text = processor.name
        
        if let toggle = cell.enabledToggle {
            toggle.isOn = processor.isEnabled
            toggle.isEnabled = settings.enabledProcessors.count == 1 ? !toggle.isOn : true
        }
        
        cell.processor = processor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 2 ? true : false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ? true : false
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard sourceIndexPath.section == 0 else { return sourceIndexPath }
        
        if proposedDestinationIndexPath.section != 0 {
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
   
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
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
            tableView.deleteRows(at: [IndexPath(row: enabledIndexPath!, section: 0)], with: .automatic)
        }
        
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return leadingActions
    }
}

extension ManagerViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.section == 0 else { return [] }
        return [UIDragItem(itemProvider: NSItemProvider())]
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard session.localDragSession != nil else { return UITableViewDropProposal(operation: .cancel, intent: .unspecified) }
        
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
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
        guard let processor = try? ProcessorModel(path: filePath!, type: .userAdded) else { return }
        
        userAddedProcessors.append(processor)
        settings.add(processor)
        
        let enabledIndexPath = IndexPath(row: settings.enabledProcessors.count - 1, section: 0)
        let userAddedIndexPath = IndexPath(row: userAddedProcessors.count - 1, section: 2)
        
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
