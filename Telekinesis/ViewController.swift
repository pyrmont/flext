//
//  ViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore

class ViewController: UIViewController, UITextViewDelegate {
    @IBOutlet var textPreview: UITextView!
    @IBOutlet var textEditor: UITextView!
    @IBOutlet var processorButton: UIButton!
    
    var jsProcessFunction: JSValue? = nil
    var defaultProcessor: String = "wrap-at-72-chars"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

        if let jsSourcePath = Bundle.main.path(forResource: filename, ofType: "js") {
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
}
