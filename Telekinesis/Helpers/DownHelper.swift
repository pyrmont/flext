//
//  DownHelper.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 2/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import Down

struct DownHelper {
    private static var fonts: FontCollection {
        var fonts = StaticFontCollection()
        fonts.heading1 = DownFont.boldSystemFont(ofSize: 20)
        fonts.heading2 = DownFont.boldSystemFont(ofSize: 19)
        fonts.heading3 = DownFont.boldSystemFont(ofSize: 18)
        fonts.heading4 = DownFont.boldSystemFont(ofSize: 17)
        fonts.heading5 = DownFont.boldSystemFont(ofSize: 16)
        fonts.heading6 = DownFont.boldSystemFont(ofSize: 15)
        fonts.body = DownFont.systemFont(ofSize: 15)
        fonts.code = DownFont(name: "menlo", size: 15) ?? .systemFont(ofSize: 15)
        fonts.listItemPrefix = DownFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        
        return fonts
    }
    
    private static var paragraphStyles: ParagraphStyleCollection {
        var paragraphStyles = StaticParagraphStyleCollection()
        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.paragraphSpacing = 18
        paragraphStyles.body = bodyStyle
        return paragraphStyles
    }
    
    static func setupStyler() -> DownStyler {
        var config = DownStylerConfiguration()
        config.fonts = fonts
        config.paragraphStyles = paragraphStyles
        return DownStyler(configuration: config)
    }
}

