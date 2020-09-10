//
//  SplitEditorViewController.swift
//  FlextMac
//
//  Created by Michael Camilleri on 1/9/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class SplitEditorViewController: EditorViewController {
//    @IBOutlet var textPreview: UITextView!
//    @IBOutlet var textEditor: TextViewWithPlaceholder!
//    @IBoutlet override var appContainerBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        textPreview.delegate = self
    }

    override func selectedProcessor() -> Processor {
        guard processor == nil else { return processor }

        processor = settings.processors.first!
        return processor
    }

    override func setupProcessorTitle(_ title: String) {
        return
    }

    override func setupPreviewHiding() {
        return
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        scrollPreview()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == textPreview {
            return false
        } else {
            return true
        }
    }
}
