//
//  EditorViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore

class EditorViewController: UIViewController {
    @IBOutlet var textPreview: UITextView!
    @IBOutlet var textEditor: UITextView!
    @IBOutlet var processorButton: UIButton!

    var settings: Settings = SettingsManager.settings
    
    var processor: Processor!
    var arguments: [Any]!
    
    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupListeners()
        setupDefaultProcessor()
    }

    // MARK: - Segues
    
    @IBAction func unwindToEditor(unwindSegue: UIStoryboardSegue) { }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController else { return }
        navigationController.presentationController?.delegate = self as UIAdaptivePresentationControllerDelegate
    }
    
    // MARK: - Listener Setup
    
    func setupListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(EditorViewController.adjustTextEditorHeight(notification:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(EditorViewController.adjustTextEditorHeight(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        
        textEditor.delegate = self
    }
    
    // MARK: - Processor Setup

    func setupDefaultProcessor() {
        setupProcessor(using: settings.selectedProcessor)
    }
    
    func setupProcessor(using processor: Processor) {
        processorButton.setTitle(processor.name, for: .normal)
        
        self.processor = processor
        self.arguments = [""]

        if self.processor.hasOptions {
            guard let context = self.processor.function?.context else { return }
            
            for option in self.processor.options {
                var javascriptValue: JSValue? = nil
                
                if let value = option.value {
                    javascriptValue = context.evaluateScript(value)
                }
                
                if javascriptValue == nil {
                    self.arguments.append(JSValue(undefinedIn: self.processor.function?.context)!)
                } else {
                    self.arguments.append(javascriptValue!)
                }
            }
        }
    }
    
    // MARK: - Processor Execution
    
    func runProcessor() {
        guard editorHasText() else { return }
        
        let text = textEditor.text ?? ""
        if text.isEmpty {
            textPreview.text = text
        } else {
            arguments[0] = text
            guard let result = processor.function?.call(withArguments: arguments) else { return }
            textPreview.text = result.toString()
        }
    }
    
    // MARK: - UI Adjustments
    
    @objc func adjustTextEditorHeight(notification: Notification) {
        if notification.name == UIResponder.keyboardDidShowNotification {
            guard let keyboardRect = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            textEditor.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardRect.cgRectValue.size.height, right: 0.0)
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            textEditor.contentInset = .zero
        }
    }
    
    // MARK: - Copying and Undoing
  
    @IBAction func copyText(_ sender: UIButton) {
        guard editorHasText() else { return }
        UIPasteboard.general.string = textPreview.text
    }
    
    @IBAction func resetText(_ sender: UIButton) {
        guard editorHasText() else { return }
        textEditor.text = ""
        textViewDidChange(textEditor)
    }
    
    // MARK: - Other Functions
    
    func returnToEditor() {
        setupProcessor(using: settings.selectedProcessor)
        runProcessor()
    }
    
    func editorHasText() -> Bool {
        let textEditor = self.textEditor as! TextViewWithPlaceholder
        return !textEditor.placeholderIsEnabled
    }
}

extension EditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        runProcessor()
    }
}

extension EditorViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        returnToEditor()
    }
}
