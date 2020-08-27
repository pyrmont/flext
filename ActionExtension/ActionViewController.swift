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
    
    enum DataType {
        case text, webpage
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
    
    var settings: Settings = SettingsManager.settings
    var enteredText = EnteredText()
    
    var selectedIndex: Int!
    var processor: Processor!
    var arguments: [Any]!

    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMargins()
        setupListeners()
        setupSelectedProcessor()
        setupTextEditor()
        
        guard let items = self.extensionContext?.inputItems as? [NSExtensionItem] else { return }
        guard let item = items.first else { return }
        guard let provider = item.attachments?.first else { return }
        
        if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
            process(provider, as: .webpage)
        } else if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
            process(provider, as: .text)
        }
    }
    
    func process(_ provider: NSItemProvider, as dataType: DataType) {
        switch dataType {
        case .text:
            provider.loadItem(forTypeIdentifier: kUTTypeText as String) { [weak self] (providedText, error) in
                OperationQueue.main.addOperation {
                    self?.enteredText.editor?.replaceText(with: providedText as? String)
                }
            }
        case .webpage:
            provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (providedDictionary, error) in
                guard let itemDictionary = providedDictionary as? NSDictionary else { return }
                guard let values = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                OperationQueue.main.addOperation {
                    self?.enteredText.editor?.replaceText(with: values["text"] as? String)
                }
            }
        }
    }
    
    // MARK: - Returning

    @IBAction func insert() {
        guard let processedText = textPreview.text else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        let extensionItem = NSExtensionItem()
        let processedDictionary = [NSExtensionJavaScriptFinalizeArgumentKey : ["text": processedText]]
        extensionItem.attachments = [NSItemProvider(item: processedDictionary as NSSecureCoding, typeIdentifier: String(kUTTypePropertyList))]
        self.extensionContext?.completeRequest(returningItems: [extensionItem], completionHandler: nil)
    }
    
    // MARK: - Segues
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard UserDefaults.standard.integer(forKey: "selectedIndex") != selectedIndex else { return }
        setupSelectedProcessor()
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
    
    func setupSelectedProcessor() {
        let selectedIndex = UserDefaults.standard.integer(forKey: "selectedIndex")
        
        if selectedIndex < settings.enabledProcessors.count {
            self.selectedIndex = selectedIndex
        } else {
            self.selectedIndex = 0
            UserDefaults.standard.set(0, forKey: "selectedIndex")
        }
        
        setupProcessor(using: settings.enabledProcessors.at(self.selectedIndex)!)
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
            // This is a hacky resolution to getting this to work on the iPad.
            // Why is the magic number 50? Your guess is as good as mine.
            if UIDevice.current.userInterfaceIdiom == .pad {
                guard let viewBottomY = view.window?.frame.maxY, keyboardViewEndFrame.minY < viewBottomY else { return }
                additionalSafeAreaInsets.bottom = (viewBottomY - keyboardViewEndFrame.minY) - inherentSafeBottom + 50
            } else {
                // This doesn't work properly when the phone is in landscape.
                // The preview view is sized correctly but content in the editor
                // view will disappear behind the keyboard _until_ you get to a
                // certian height, at which point it will scroll correctly into
                // view. Why is the scroll view not working properly? Again,
                // your guess is as good as mine.
                additionalSafeAreaInsets.bottom = keyboardViewEndFrame.height - inherentSafeBottom
            }
        }
        
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
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

extension ActionViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        runProcessor()
    }
}
