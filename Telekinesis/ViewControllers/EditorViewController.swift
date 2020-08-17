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
    @IBOutlet var appContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var textPreview: UITextView!
    @IBOutlet var textEditor: UITextView!
    @IBOutlet var processorButton: UIButton!

    var settings: Settings = SettingsManager.settings
    
    var processor: Processor!
    var arguments: [Any]!
    
    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMargins()
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
            name: UIResponder.keyboardWillShowNotification,
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
    
    func setupMargins() {
        let marginReduction = -(textPreview.textContainer.lineFragmentPadding)
        textPreview.textContainerInset.left = marginReduction
        textPreview.textContainerInset.right = marginReduction
        textEditor.textContainerInset.left = marginReduction
        textEditor.textContainerInset.right = marginReduction
    }
    
    @objc func adjustTextEditorHeight(notification: Notification) {
        if notification.name == UIResponder.keyboardWillShowNotification {
            guard let keyboardRect = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let thirdKeyboardHeight = keyboardRect.cgRectValue.size.height / 3
            
            textEditor.contentInset.bottom = thirdKeyboardHeight
            appContainerBottomConstraint.constant = -(thirdKeyboardHeight * 2)
            
            view.setNeedsLayout()
            UIView.animate(withDuration: 0.5) { self.view.layoutIfNeeded() }
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            textEditor.contentInset.bottom = textPreview.contentInset.bottom
            appContainerBottomConstraint.constant = .zero
            
            view.setNeedsLayout()
            UIView.animate(withDuration: 0.5) { self.view.layoutIfNeeded() }
        }
    }
    
    // MARK: - Copying, Pasting and Resetting
  
    @IBAction func copyText(_ sender: UIButton) {
        guard editorHasText() else { return }
        UIPasteboard.general.string = textPreview.text
    }
    
    @IBAction func resetText(_ sender: UIButton) {
        guard editorHasText() else { return }
        textEditor.text = ""
        textViewDidChange(textEditor)
    }
    
    @IBAction func interactWithText(_ sender: UISegmentedControl) {
        guard editorHasText() else { return }
        switch sender.selectedSegmentIndex {
        case 0:
            textEditor.text = ""
            textViewDidChange(textEditor)
        case 1:
            UIPasteboard.general.string = textPreview.text
        case 2:
            guard let paste = UIPasteboard.general.string else { return }
            textEditor.text = paste
            textViewDidChange(textEditor)
        default:
            break
        }
    }
    
    // MARK: - Other Functions
    
    func returnToEditor() {
        DispatchQueue.global(qos: .background).async {
            PreferencesManager.save(self.settings.processors, ordering: self.settings.enabledProcessors, selected: self.settings.selectedProcessor)
        }
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
