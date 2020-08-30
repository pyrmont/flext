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

/**
 Displays an internal webpage.
 
 With the exception of the About screen, pages of information in Flext are
 rendered as webpages that are viewed through a `WKWebView` instance.
 */
class WebpageViewController: UIViewController {
    
    // MARK: - IB Outlet Values
    
    @IBOutlet var pageTitle: UINavigationItem!
    @IBOutlet var webView: WKWebView!
    
    // MARK: - Properties
    
    /// The `Webpage` object to render.
    var webpage: Webpage!
    
    // MARK: - Controller Loading
    
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
            NSLog("Navigation failed")
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

    // MARK: - E-mail Composition

    /**
     Presents an e-mail composing screen to the user.
     
     If a user taps on a `mailto` link in a webpage, this method presents an
     e-mail composition screen. The given `address` is inserted, the subject
     `[Flext]` is inserted and the body is set to be blank.
     
     - Parameters:
        - address: The address to which this e-mail will be sent.
     */
    func composeEmail(to address: String) {
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

