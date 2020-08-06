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

    @IBAction func unwindToEditor(unwindSegue: UIStoryboardSegue) { }
    
    var processor: ProcessorModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupListeners()
        setupDefaultProcessor()
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
        let firstPath = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "Processors")![0]
        setupProcessor(using: try! ProcessorModel(path: firstPath))
    }
    
    func setupProcessor(using processor: ProcessorModel) {
        self.processor = processor
        processorButton.setTitle(processor.name, for: .normal)
    }
    
    // MARK: - Processor Execution
    
    func runProcessor() {
        guard editorHasText() else { return }
        guard let result = processor.function?.call(withArguments: [textEditor.text ?? ""]) else { return }
        textPreview.text = result.toString()
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
