//
//  ButtonWithRoundedCorners.swift
//  Flext
//
//  Created by Michael Camilleri on 31/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

/**
 Represents a rounded button.
 
 Interface Builder does not include an in-built mechanism for rounding the
 corners of buttons. Well, you can do the user-defined runtime attributes but
 I took this approach instead.
*/
class ButtonWithRoundedCorners: UIButton {
    
    // MARK: - Initialisers
    override init(frame: CGRect) {
        super.init(frame: frame)
        roundCorners()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        roundCorners()
    }

    // MARK: - Button Rounding
    
    /**
     Rounds the corners of the button.
     
     This function uses `UIColor.clear.cgColor` for the border colour. I haven't
     seen other people take this approach and am not sure if that's for a
     reason. In my testing, it seemed to work fine.
     */
    private func roundCorners() {
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 10
    }
}
