//
//  TextViewWithPlaceholder.swift
//  Flext
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

/**
 Represents a text view with placeholder text.
 
 `UITextView` does not include support for placeholder text (like
 `UITextField`). This class subclasses `UITextView` and adds placeholder
 support.
 */
class TextViewWithPlaceholder: UITextView {
    
    // MARK: - Properties
    
    /// The default text colour when the text view has text.
    var activeTextColor: UIColor = .label
    
    /// The default placeholder text.
    var placeholderText: String = "Enter your text."
    
    /// The default text colour when the text view has placeholder text.
    var placeholderColor: UIColor? = .placeholderText

    /// The state of whether the placeholder text is enabled or not.
    var placeholderIsEnabled: Bool = true

    // MARK: - Initialisers
    
    /**
     Creates a text view with specified placeholder text in a particular colour.
     
     - Parameters:
        - frame: The frame for the text view.
        - textContainer: The text container for the text view.
        - placeholderText: The text to use for the placeholder.
        - placeholderColor: The colour to use for the placeholder text.
        - activeTextColor: The colour to use for the text view when it has text.
     */
    init(frame: CGRect, textContainer: NSTextContainer?, placeholderText: String, placeholderColor: UIColor, activeTextColor: UIColor? = nil) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
        
        self.placeholderText = placeholderText
        self.placeholderColor = placeholderColor
        if activeTextColor != nil { self.activeTextColor = activeTextColor! }
    }
    
    /**
     Creates a text view with default values.
     
     - Parameters:
        - frame: The frame for the text view.
        - textContainer: The text container for the text view.
     */
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
    }
    
    /**
     Creates a text view using a coder.
     
     - Parameters:
        - coder: The coder to use for the text view.
     */
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
    }

    // MARK: - Placeholder Setup
    
    /**
     Sets up the placeholder.
     */
    private func setupPlaceholder() {
        placeholderText = self.text
        placeholderColor = self.textColor
    }
    
    // MARK: - Placeholder Updating

    override func becomeFirstResponder() -> Bool {
        if placeholderIsEnabled {
            self.text = nil
            self.textColor = activeTextColor
            placeholderIsEnabled = false
        }
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        if self.text == nil || self.text.isEmpty {
            self.text = placeholderText
            self.textColor = placeholderColor
            placeholderIsEnabled = true
        }
        return super.resignFirstResponder()
    }
    

    // MARK: - Text Changes

    /**
     Replaces the text in the text view.
     
     This also calls the delegate's `textViewDidChange` method if a delegate
     exists.
     
     - Parameters:
        - text: The text to use.
        - allowEmpty: Whether the new text can be an empty string.
     */
    func replaceText(with text: String?, allowEmpty: Bool = false) {
        guard self.text != text else { return }
        
        if let text = text, !text.isEmpty || allowEmpty {
            self.text = text
            self.textColor = self.activeTextColor
            self.placeholderIsEnabled = false
        } else {
            self.text = self.placeholderText
            self.textColor = self.placeholderColor
            self.placeholderIsEnabled = true
        }
        
        delegate?.textViewDidChange?(self)
    }
    
    /**
     Appends text to the text view.
     
     This also calls the delegate's `textViewDidChange` method if a delegate
     exists.
     
     - Parameters:
        - addition: The text to add.
     */
    func appendText(with addition: String?) {
        guard let addition = addition else { return }
        
        if self.placeholderIsEnabled {
            self.text = addition
            self.textColor = self.activeTextColor
            self.placeholderIsEnabled = false
        } else {
            self.text += addition
        }
        
        delegate?.textViewDidChange?(self)
    }
}
