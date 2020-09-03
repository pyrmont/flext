//
//  UIViewExtension.swift
//  Flext
//
//  Created by Michael Camilleri on 31/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
extension UIView {
    @objc(_focusRingType)
    var focusRingType: UInt {
        return 1 //NSFocusRingTypeNone
    }
}
#endif
