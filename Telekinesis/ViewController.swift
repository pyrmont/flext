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
    
    var jsProcessFunction: JSValue? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textEditor.delegate = self
        setupProcessor()
    }
    
    func setupProcessor(using filename: String = "wrap-at-72-chars") {
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
