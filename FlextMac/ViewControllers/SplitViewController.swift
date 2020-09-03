//
//  SplitViewController.swift
//  FlextMac
//
//  Created by Michael Camilleri on 1/9/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        #if targetEnvironment(macCatalyst)
        self.primaryBackgroundStyle = .sidebar
        #endif

        // Do any additional setup after loading the view.
    }

}
