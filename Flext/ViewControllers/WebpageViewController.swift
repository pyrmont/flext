//
//  WebpageViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 22/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import MessageUI
import WebKit

class WebpageViewController: UIViewController {
    @IBOutlet var pageTitle: UINavigationItem!
    @IBOutlet var webView: WKWebView!
    
    var webpage: Webpage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageTitle.title = webpage.title
        
        webView.navigationDelegate = self
        
        webView.loadHTMLString(webpage.output(to: .html), baseURL: webpage.baseURL)
    }
}

extension WebpageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            print("Navigation failed")
            return
        }
        
        switch url.scheme?.lowercased() {
        case "file":
            decisionHandler(.allow)
        case "mailto":
            composeEmail(to: String(url.absoluteString.dropFirst(7)))
            decisionHandler(.cancel)
        default:
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}

extension WebpageViewController: MFMailComposeViewControllerDelegate {
    func composeEmail(to address: String) {
        print(address)
        guard MFMailComposeViewController.canSendMail() else { return }

        let subject = "[Flext]"
        let body = ""

        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients([address])
        mail.setSubject(subject)
        mail.setMessageBody(body, isHTML: false)

        present(mail, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

