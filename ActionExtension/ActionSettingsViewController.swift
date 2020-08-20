//
//  ActionSettingsViewController.swift
//  ActionExtension
//
//  Created by Michael Camilleri on 19/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

// MARK: - Action Settings Table View Cell Definition

class ActionSettingsTableViewCell: UITableViewCell {
    let selectedCellImage = UIImage(systemName: "smallcircle.fill.circle.fill")
    var originalCellImage: UIImage!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            originalCellImage = originalCellImage ?? imageView?.image
            imageView?.image = selectedCellImage
        } else {
            imageView?.image = originalCellImage ?? imageView?.image
        }
    }
}

class ActionSettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
