//
//  ViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {
    @IBOutlet var textPreview: UITextView!
    @IBOutlet var textEditor: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textEditor.delegate = self
    }
    
    // UITextViewDelegate Methods
    
    func textViewDidChange(_ textView: UITextView) {
        textPreview.text = textView.text
    }
}
