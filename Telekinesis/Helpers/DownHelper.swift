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
        fonts.heading1 = DownFont(name: "Gill Sans", size: 20) ?? DownFont.boldSystemFont(ofSize: 20)
        fonts.heading2 = DownFont(name: "Gill Sans", size: 19) ?? DownFont.boldSystemFont(ofSize: 19)
        fonts.heading3 = DownFont.boldSystemFont(ofSize: 18)
        fonts.heading4 = DownFont.boldSystemFont(ofSize: 17)
        fonts.heading5 = DownFont.boldSystemFont(ofSize: 16)
        fonts.heading6 = DownFont.boldSystemFont(ofSize: 15)
        fonts.body = DownFont.systemFont(ofSize: 15)
        fonts.code = DownFont(name: "Menlo", size: 15) ?? .systemFont(ofSize: 15)
        fonts.listItemPrefix = DownFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        
        return fonts
    }
    
    private static var colors: ColorCollection {
        var colors = StaticColorCollection()
        colors.heading1 = #colorLiteral(red: 0.05490196078, green: 0.6941176471, blue: 0.862745098, alpha: 1)
        colors.heading2 = #colorLiteral(red: 0.2033254802, green: 0.8706358671, blue: 0.8038175702, alpha: 1)
        colors.body = .darkGray
        
        return colors
    }
    
    private static var listOptions: ListItemOptions {
        var listOptions = ListItemOptions()
        
        listOptions.spacingAbove = 10
        listOptions.spacingBelow = 10
        
        return listOptions
    }
    
    private static var paragraphStyles: ParagraphStyleCollection {
        var paragraphStyles = StaticParagraphStyleCollection()
        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.paragraphSpacing = 10
        bodyStyle.paragraphSpacingBefore = 10
        paragraphStyles.body = bodyStyle

        let headingStyle1 = NSMutableParagraphStyle()
        paragraphStyles.heading1 = headingStyle1
        
        let headingStyle2 = NSMutableParagraphStyle()
        headingStyle2.paragraphSpacing = 0
        headingStyle2.paragraphSpacingBefore = 8
        paragraphStyles.heading2 = headingStyle2
        
        return paragraphStyles
    }
    
    static func setupStyler() -> DownStyler {
        var config = DownStylerConfiguration()
        config.fonts = fonts
        config.colors = colors
        config.listItemOptions = listOptions
        config.paragraphStyles = paragraphStyles
        return DownStyler(configuration: config)
    }
}

