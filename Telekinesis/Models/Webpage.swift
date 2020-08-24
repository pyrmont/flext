//
//  Webpage.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 23/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation
import Down

struct Webpage {
    enum Format {
        case html
    }

    private static let dataDirectory: String = "Webpages"

    var title: String
    var sourceFile: String
    let baseURL: URL = Bundle.main.bundleURL.appendingPathComponent(Webpage.dataDirectory)
    
    private var topHTML: String {
        let template = try! String(contentsOf: Bundle.main.url(forResource: "page_top", withExtension: "html", subdirectory: Webpage.dataDirectory)!)
        return template.replacingOccurrences(of: "{{ title }}", with: title)
    }
    
    private var bottomHTML: String {
        return try! String(contentsOf: Bundle.main.url(forResource: "page_bottom", withExtension: "html", subdirectory: Webpage.dataDirectory)!)
    }
    
    func output(to format: Format) -> String {
        switch format {
        case .html:
            let content = try! String(contentsOf: Bundle.main.url(forResource: sourceFile, withExtension: "", subdirectory: Webpage.dataDirectory)!)
            let down = Down(markdownString: content)
            let contentHTML = try! down.toHTML(.smartUnsafe)
            return topHTML + contentHTML + bottomHTML
        }
    }
}
