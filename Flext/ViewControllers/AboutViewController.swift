//
//  AboutViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 1/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

/**
 Displays the About screen.
 */
class AboutViewController: UIViewController {
    
    // MARK: - IB Outlet Values
    
    @IBOutlet var versionLabel: UILabel!

    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionLabel.text = "v\(appVersion) (\(buildVersion))"
        }

    }
    
    // MARK: - Link Opening
    
    /**
     Opens a link with the appropriate URL.
     
     Depending on the text label of the button, this opens the appropriate URL.
     The URL should be attached to the button via the storyboard rather than
     hardcoding it here.
     
     - Parameters:
        - sender: The button that triggered the link (this should be one of the
                  buttons in the About screen).
     */
    @IBAction func openLink(_ sender: UIButton) {
        var destination: URL?
        
        switch sender.titleLabel?.text {
        case "Repository":
            destination = URL(string: "https://github.com/pyrmont/flext")
        case "Website":
            destination = URL(string: "https://inqk.net")
        default:
            break
        }
        
        guard destination != nil else { return }
        UIApplication.shared.open(destination!)
    }
}
