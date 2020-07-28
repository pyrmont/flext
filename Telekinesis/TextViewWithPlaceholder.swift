//
//  TextViewWithPlaceholder.swift
//  Telekinesis
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class TextViewWithPlaceholder: UITextView {
    var activeTextColor: UIColor = .black
    
    var placeholderText: String = "Enter your text."
    var placeholderColor: UIColor? = .lightGray

    var placeholderEnabled: Bool = true

    // MARK: Initialisation
    
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
    
    // MARK: Deinitialisation
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Placeholder Updating
    
    @objc private func textDidBeginEditing(notification: Notification) {
        guard placeholderEnabled else { return }

        self.text = nil
        self.textColor = self.activeTextColor
        self.placeholderEnabled = false
    }
    
    @objc private func textDidEndEditing(notification: Notification) {
        guard self.text.isEmpty else { return }

        self.text = self.placeholderText
        self.textColor = self.placeholderColor
        self.placeholderEnabled = true
    }
}
