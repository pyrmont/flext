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
    
    var jsProcessFunction: JSValue? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupListeners()
        setupProcessor()
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

    func setupProcessor() {
        let defaultProcessor = ProcessorModel(path: Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "Processors")![0])
        setupProcessor(using: defaultProcessor)
    }
    
    func setupProcessor(using processor: ProcessorModel) {
        setupProcessorButton(using: processor)
        setupProcessorFunction(using: processor)
    }
    
    func setupProcessorButton(using processor: ProcessorModel) {
        processorButton.setTitle(processor.name, for: .normal)
    }
    
    func setupProcessorFunction(using processor: ProcessorModel) {
        guard let jsContext = JSContext() else { return }

        do {
            let jsSourceContents = try String(contentsOf: processor.path)
            jsContext.evaluateScript(jsSourceContents)
            jsProcessFunction = jsContext.objectForKeyedSubscript("process")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Processor Execution
    
    func runProcessor() {
        guard let textEditor = textEditor as? TextViewWithPlaceholder, !textEditor.placeholderIsEnabled else { return }
        guard let result = jsProcessFunction?.call(withArguments: [textEditor.text ?? ""]) else { return }
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
}

extension EditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        runProcessor()
    }
}
