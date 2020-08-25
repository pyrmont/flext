//
//  EditorViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore

class EditorViewController: UIViewController {
    enum Button: Int {
        case reset, copy, paste
    }
    
    struct EnteredText {
        var hasBeenRestored = false

        var editor: TextViewWithPlaceholder?
        var previousValue: String?

        var value: String? {
            guard let editor = editor else { return nil }
            
            return editor.placeholderIsEnabled ? nil : editor.text
        }

        var hasValue: Bool { value != nil }
        var hasPreviousValue: Bool { previousValue != nil }
    }
    
    @IBOutlet var appContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var textPreview: UITextView!
    @IBOutlet var textEditor: UITextView!
    @IBOutlet var processorButton: UIButton!

    var settings: Settings = SettingsManager.settings
    var enteredText = EnteredText()
    
    var processor: Processor!
    var arguments: [Any]!
    
    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUserActivity()
        setupMargins()
        setupListeners()
        setupDefaultProcessor()
        setupTextEditor()
    }

    // MARK: - Segues
    
    @IBAction func unwindToEditor(unwindSegue: UIStoryboardSegue) { }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController else { return }
        navigationController.presentationController?.delegate = self as UIAdaptivePresentationControllerDelegate
    }
    
    func returnToEditor() {
        DispatchQueue.global(qos: .background).async {
            PreferencesManager.save(self.settings.processors, ordering: self.settings.enabledProcessors, selected: self.settings.selectedProcessor)
        }
        setupProcessor(using: settings.selectedProcessor)
        runProcessor()
    }
    
    // MARK: - State Restoration
    
    func setupUserActivity() {
        self.userActivity = NSUserActivity(activityType: "net.inqk.Flext.staterestoration.editing")
        self.userActivity?.title = "Editor"
    }
    
    func hasActivity() -> Bool {
        return enteredText.value != nil
    }
    
    func persistActivity() {
        self.userActivity?.userInfo?["editorText"] = enteredText.value
    }
    
    func restoreActivity(using activity: NSUserActivity) {
        enteredText.previousValue = activity.userInfo?["editorText"] as? String
        enteredText.hasBeenRestored = false
    }
    
    // MARK: - Listener Setup
    
    func setupListeners() {
        textEditor.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustTextEditorHeight(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustTextEditorHeight(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

        textEditor.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Processor Setup

    func setupDefaultProcessor() {
        setupProcessor(using: settings.selectedProcessor)
    }
    
    func setupProcessor(using processor: Processor) {
        processorButton.setTitle(processor.name, for: .normal)
        UIView.animate(withDuration: 0) { self.view.layoutIfNeeded() }
        
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
    
    // MARK: - Text Editor Setup
    
    func setupTextEditor() {
        enteredText.editor = textEditor as? TextViewWithPlaceholder
        
        if enteredText.hasPreviousValue {
            enteredText.editor?.replaceText(with: enteredText.previousValue)
        }
    }
    
    // MARK: - Processor Execution
    
    func runProcessor() {
        guard let text = enteredText.value else { return }
        
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
        if notification.name == UIResponder.keyboardWillChangeFrameNotification {
            guard let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let keyboardHeight = keyboardRect.cgRectValue.size.height

            if traitCollection.verticalSizeClass != .compact && traitCollection.horizontalSizeClass != .regular {
                appContainerBottomConstraint.constant = keyboardHeight * 0.6
                textEditor.contentInset.bottom = keyboardHeight * 0.4
            } else {
                appContainerBottomConstraint.constant = keyboardHeight
            }
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            appContainerBottomConstraint.constant = .zero
            textEditor.contentInset.bottom = .zero
        }

        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        view.setNeedsLayout()
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    
    // MARK: - Copying, Pasting and Resetting
    
    @IBAction func interactWithText(_ sender: UISegmentedControl) {
        guard enteredText.hasValue else { return }
        
        switch Button(rawValue: sender.selectedSegmentIndex) {
        case .reset:
            enteredText.editor?.replaceText(with: "", allowEmpty: true)
        case .copy:
            UIPasteboard.general.string = textPreview.text
        case .paste:
            guard let paste = UIPasteboard.general.string else { return }
            enteredText.editor?.appendText(with: paste)
        default:
            break
        }
    }
}

// MARK: - Text View Delegate

extension EditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        runProcessor()
    }
}

// MARK: - Presentation Controller Delegate

extension EditorViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        returnToEditor()
    }
}
