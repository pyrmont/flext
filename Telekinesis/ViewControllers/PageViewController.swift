//
//  PageViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 1/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import Down

class PageViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    
    var textKey: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let down = Down(markdownString: Bundle.main.localizedString(forKey: textKey, value: nil, table: nil))
        let attributedString = try? down.toAttributedString(.default, styler: DownHelper.setupStyler())
        textView.attributedText = attributedString
    }
}
