//
//  AboutViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 1/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

// MARK: - AboutRoundedButton Class
/**
 Represents a rounded button.
 
 Interface Builder does not include an in-built mechanism for rounding the
 corners of buttons. Well, you can do the user-defined runtime attributes but
 I took this approach instead.
 */
class AboutRoundedButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        roundCorners()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        roundCorners()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        roundCorners()
    }

    /**
     Rounds the corners of the button.
     */
    private func roundCorners() {
        self.layer.cornerRadius = 10
        self.layer.borderColor = UIColor.systemBackground.cgColor
        self.layer.borderWidth = 1.0
    }
}

// MARK: - AboutViewController Class
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
