//
//  ActionViewController.swift
//  ActionExtension
//
//  Created by Michael Camilleri on 19/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore
import MobileCoreServices

// MARK: - Action View Controller Definition

class ActionViewController: UIViewController {
    enum Button: Int {
        case reset, copy, paste
    }
    
    struct EnteredText {
        var editor: TextViewWithPlaceholder?

        var value: String? {
            guard let editor = editor else { return nil }
            
            return editor.placeholderIsEnabled ? nil : editor.text
        }

        var hasValue: Bool { value != nil }
    }

    @IBOutlet var processorTitle: UINavigationItem!
    @IBOutlet var textPreview: UITextView!
    @IBOutlet var textEditor: UITextView!
    
    var initialSafeAreaBottom: CGFloat!
    
    var settings: Settings = SettingsManager.settings
    var enteredText = EnteredText()
    
    var processor: Processor!
    var arguments: [Any]!

    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSafeAreaBottom = view.safeAreaInsets.bottom
        
        setupMargins()
        setupListeners()
        setupDefaultProcessor()
        setupTextEditor()
        
        guard let items = self.extensionContext?.inputItems as? [NSExtensionItem] else { return }
        guard let item = items.first else { return }
        guard let provider = item.attachments?.first else { return }
        guard provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) else { return }
        
        weak var weakTextEditor = enteredText.editor
        
        provider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil, completionHandler: { (text, error) in
            OperationQueue.main.addOperation {
                guard let textEditor = weakTextEditor else { return }
                guard let text = text as? String else { return }
                textEditor.replaceText(with: text)
            }
        })
    }
    
    // MARK: - Returning

    @IBAction func insert() {
        guard let processedText = textPreview.text else { return }
        guard let data = processedText.data(using: .utf8) else { return }
        let provider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeText as String)
        let item = NSExtensionItem()
        item.attachments?.append(provider)
        self.extensionContext!.completeRequest(returningItems: [item], completionHandler: nil)
    }
    
    // MARK: - Segues
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard settings.selectedProcessor != processor else { return }
        setupProcessor(using: settings.selectedProcessor)
        runProcessor()
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
        self.processorTitle.title = processor.name
        
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
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        additionalSafeAreaInsets.bottom = 0
        let inherentSafeBottom = view.safeAreaInsets.bottom
        
        if notification.name != UIResponder.keyboardWillHideNotification {
            additionalSafeAreaInsets.bottom = keyboardViewEndFrame.height - inherentSafeBottom
        }
        
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        view.setNeedsLayout()
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    
    // MARK: - Copying, Pasting and Resetting
  
    @IBAction func interactWithText(_ sender: UISegmentedControl) {
        guard enteredText.hasValue else { return }
        
        switch sender.selectedSegmentIndex {
        case Button.reset.rawValue:
            enteredText.editor?.replaceText(with: "", allowEmpty: true)
        case Button.copy.rawValue:
            UIPasteboard.general.string = enteredText.value
        case Button.paste.rawValue:
            guard let paste = UIPasteboard.general.string else { return }
            enteredText.editor?.appendText(with: paste)
        default:
            break
        }
    }
}

// MARK: - Text View Delegate

extension ActionViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        runProcessor()
    }
}
