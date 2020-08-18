//
//  TextViewWithPlaceholder.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class TextViewWithPlaceholder: UITextView {
    var activeTextColor: UIColor = .label
    
    var placeholderText: String = "Enter your text."
    var placeholderColor: UIColor? = .placeholderText

    var placeholderIsEnabled: Bool = true

    // MARK: - Initialisation
    
    init(frame: CGRect, textContainer: NSTextContainer?, placeholderText: String, placeholderColor: UIColor, activeTextColor: UIColor? = nil) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
        
        self.placeholderText = placeholderText
        self.placeholderColor = placeholderColor
        if activeTextColor != nil { self.activeTextColor = activeTextColor! }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
    }
    
    private func setupPlaceholder() {
        placeholderText = self.text
        placeholderColor = self.textColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(TextViewWithPlaceholder.textDidBeginEditing(notification:)), name: UITextView.textDidBeginEditingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TextViewWithPlaceholder.textDidEndEditing(notification:)), name: UITextView.textDidEndEditingNotification, object: nil)
    }
    
    // MARK: - Deinitialisation
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Placeholder Updating
    
    @objc private func textDidBeginEditing(notification: Notification) {
        guard placeholderIsEnabled else { return }

        self.text = nil
        self.textColor = self.activeTextColor
        self.placeholderIsEnabled = false
    }
    
    @objc private func textDidEndEditing(notification: Notification) {
        guard self.text.isEmpty else { return }

        self.text = self.placeholderText
        self.textColor = self.placeholderColor
        self.placeholderIsEnabled = true
    }
    
    // MARK: - Text Changes
    
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
