//
//  EditorViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore

class EditorViewController: UIViewController, UITextViewDelegate {
    @IBOutlet var textPreview: UITextView!
    @IBOutlet var textEditor: UITextView!
    @IBOutlet var processorButton: UIButton!
    
    var jsProcessFunction: JSValue? = nil
    var defaultProcessor: String = "wrap-at-72-chars"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.adjustTextEditorHeight(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.adjustTextEditorHeight(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        textEditor.delegate = self
        setupProcessor(using: defaultProcessor)
    }
    
    // Processor Setup
    
    func setupProcessor(using filename: String) {
        setupProcessorButton(using: filename)
        setupProcessorFunction(using: filename)
    }
    
    func setupProcessorButton(using filename: String) {
        let prettyName = filename.capitalized.replacingOccurrences(of: "-", with: " ")
        processorButton.setTitle(prettyName, for: .normal)
    }
    
    func setupProcessorFunction(using filename: String) {
        guard let jsContext = JSContext() else { return }

        if let jsSourcePath = Bundle.main.path(forResource: filename, ofType: "js", inDirectory: "Processors") {
            do {
                let jsSourceContents = try String(contentsOfFile: jsSourcePath)
                jsContext.evaluateScript(jsSourceContents)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        jsProcessFunction = jsContext.objectForKeyedSubscript("process")
    }
    
    // UITextViewDelegate Methods
    
    func textViewDidChange(_ textView: UITextView) {
        guard let result = jsProcessFunction?.call(withArguments: [textView.text ?? ""]) else { return }
        
        textPreview.text = result.toString()
    }
    
    @objc func adjustTextEditorHeight(notification: Notification) {
        if notification.name == UIResponder.keyboardDidShowNotification {
            guard let keyboardRect = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            textEditor.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardRect.cgRectValue.size.height, right: 0.0)
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            textEditor.contentInset = .zero
        }
    }
}
