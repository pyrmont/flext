//
//  WebpageViewController.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 22/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import WebKit

class WebpageViewController: UIViewController {
    @IBOutlet var pageTitle: UINavigationItem!
    @IBOutlet var webView: WKWebView!
    
    var webpage: Webpage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageTitle.title = webpage.title
        
        webView.loadHTMLString(webpage.output(to: .html), baseURL: webpage.baseURL)
    }
}

