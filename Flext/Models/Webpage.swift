//
//  Webpage.swift
//  Flext
//
//  Created by Michael Camilleri on 23/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import Foundation
import Down

/**
 Represents a webpage.
 
 Internal webpages consist of a Markdown file that can be rendered into
 different formats. These files are used for the display of extended-length
 information throughout Flext.
 */
struct Webpage {
    
    // MARK: - Format Enum
    
    /**
     Represents the format of the output.
     
     At present, the only supported output is HTML.
     */
    enum Format {
        case html
    }

    // MARK: - Class Properties
    
    /// The directory name where the webpage files are stored.
    private static let dataDirectory: String = "Webpages"

    // MARK: - Properties
    
    /// The title of the webpage.
    var title: String
    
    /// The source file of the Markdown file.
    var sourceFile: String
    
    /// The URL for the data directory.
    ///
    /// This is used as the base directory when rendering HTML in case that HTML
    /// contains references to local files (such as CSS or JavaScript).
    let baseURL: URL = Bundle.main.resourceURL!.appendingPathComponent(Webpage.dataDirectory)
    
    /// The HTML at the top of the page.
    private var topHTML: String {
        let template = try! String(contentsOf: Bundle.main.url(forResource: "page_top", withExtension: "html", subdirectory: Webpage.dataDirectory)!)
        return template.replacingOccurrences(of: "{{ title }}", with: title)
    }
    
    // The HTML at the bottom of the page.
    private var bottomHTML: String {
        return try! String(contentsOf: Bundle.main.url(forResource: "page_bottom", withExtension: "html", subdirectory: Webpage.dataDirectory)!)
    }
    
    // MARK: - Rendering
    
    /**
     Outputs the webpage to a format.
     
     - Parameters:
        - format: The format for the output.
     
     - Returns: The webpage in the format.
     */
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
