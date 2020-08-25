//
//  AboutViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 1/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import Down

class AboutRoundedButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        roundCorners()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        roundCorners()
    }
    
    private func roundCorners() {
        self.layer.cornerRadius = 10
        self.layer.borderColor = UIColor.systemBackground.cgColor
        self.layer.borderWidth = 1.0
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        roundCorners()
    }
}

class AboutViewController: UIViewController {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
