//
//  EditorViewController.swift
//  Flext
//
//  Created by Michael Camilleri on 28/7/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore

/**
 Displays the editing interface of Flext.
 
 While this class is primarily used to display the editing interface in the app
 proper, a subclass, `ActionViewController`, is used in the action extension.
 */
class EditorViewController: UIViewController {

    // MARK: - Button Enum
    /**
     Represents the `reset`, `copy` and `paste` buttons.
     */
    enum Button: Int {
        case reset, copy, paste
    }
    
    // MARK: - EnteredText Struct
    
    /**
     Represents text entered into the editor.
     
     Flext uses a custom class, `TextViewWithPlaceholder`, to add a placeholder
     to the editor's text view that has similar functionality to a placeholder
     in a `UITextField` element. This text complicates functionality like state
     restoration.
     
     This struct avoids those problems by providing properties that return
     values that are aware of the status of the placeholder text.
     */
    struct EnteredText {
        
        /// The editor's text view.
        var editor: TextViewWithPlaceholder?
        
        /// The status of whether the entered text has been restored.
        var hasBeenRestored = false
        
        /// The text that was previously entered before the state was saved
        /// (if any).
        var previousValue: String?

        /// The value of the entered text.
        ///
        /// This value is `nil` if the placeholder text is active.
        var value: String? {
            guard let editor = editor else { return nil }
            
            return editor.placeholderIsEnabled ? nil : editor.text
        }

        /// The status of whether `value` is `nil`.
        var hasValue: Bool { value != nil }
        
        /// The status of whether `previousValue` has been set.
        var hasPreviousValue: Bool { previousValue != nil }
    }
    
    // MARK: - IB Outlet Values
    
    @IBOutlet var appContainer: UIStackView!
    @IBOutlet var textPreview: UITextView!
    @IBOutlet var textEditor: UITextView!
    @IBOutlet var previewHeading: UIButton!
    @IBOutlet var processorButton: UIButton!

    @IBOutlet var appContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var textPreviewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties

    /// The settings for Flext.
    var settings: Settings = SettingsManager.settings
    
    /// The entered text.
    var enteredText = EnteredText()
    
    /// The active processor.
    var processor: Processor!
    
    /// The arguments for the processor.
    var arguments: [Any]!
    
    /// The status of whether the text preview is hidden.
    var previewIsHidden: Bool {
        textPreviewHeightConstraint.isActive
    }
    
    // MARK: - Controller Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUserActivity()
        setupMargins()
        setupListeners()
        setupDefaultProcessor()
        setupPreviewHiding()
        setupTextEditor()
    }

    // MARK: - Segues
    
    /**
     Unwinds to the Editor.
     
     This method is necessary for other screens to be able to unwind back to the
     Editor. It is intentionally empty.
     
     - Parameters:
        - unwindSegue: The unwinding segue.
     */
    @IBAction func unwindToEditor(unwindSegue: UIStoryboardSegue) { }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController else { return }
        navigationController.presentationController?.delegate = self as UIAdaptivePresentationControllerDelegate
    }
    
    /**
     Prepares the editor for being the frontmost view.
     
     When the editor becomes the frontmost view, various updates need to be made
     to update elements of the view. This method:
     
     1. saves the selected processor to Flext's preferences file in the
        background;
     2. sets the editor's active processor to be the one selected in Flext's
        settings; and
     3. runs the active processor over the entered text.
     */
    func returnToEditor() {
        DispatchQueue.global(qos: .background).async {
            PreferencesManager.save(self.settings.processors, ordering: self.settings.enabledProcessors, selected: self.settings.selectedProcessor)
        }
        setupProcessor(using: settings.selectedProcessor)
        runProcessor()
    }
    
    // MARK: - State Restoration
    
    /**
     Creates an `NSUserActivity` object for storing user activity.
     
     UIKit's state restoration frameworks look for an `NSUserActivity` to be
     stored on the view controller's `uesrActivity` property. This method sets
     one up for state restoration.
     */
    func setupUserActivity() {
        self.userActivity = NSUserActivity(activityType: "net.inqk.Flext.staterestoration.editing")
        self.userActivity?.title = "Editor"
    }
    
    /**
     Returns whether activity has occurred.
     
     To determine whether the state of the editor shuold be saved, Flext's
     `SceneDelegate` object checks whether 'activity' has occurred. In Flext's
     case that means whether text has been entered into the editor.
     */
    func hasActivity() -> Bool {
        return enteredText.value != nil
    }
    
    /**
     Captures the user activity.
     
     This method adds the value of the text editor to the user activity object.
     */
    func persistActivity() {
        self.userActivity?.userInfo?["editorText"] = enteredText.value
    }
    
    /**
     Restores the user activity.
     
     This method sets the `previousValue` of the `enteredText` struct to be the
     value loaded from the previous state save.
     */
    func restoreActivity(using activity: NSUserActivity) {
        enteredText.previousValue = activity.userInfo?["editorText"] as? String
        enteredText.hasBeenRestored = false
    }
    
    // MARK: - Listener Setup

    /**
     Sets up the text editor's delegate.
     */
    func setupListeners() {
        textEditor.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustTextEditorHeight(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustTextEditorHeight(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

        textEditor.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        scrollPreview()
        
        if traitCollection.verticalSizeClass == .compact || traitCollection.horizontalSizeClass == .regular {
            previewHeading.isEnabled = false
            if previewIsHidden {
                togglePreview()
            }
        } else {
            previewHeading.isEnabled = true
        }
    }

    // MARK: - Processor Setup

    /**
     Sets up the default processor.
     
     This method uses the selected processor that is saved in Flext's settings.
     */
    func setupDefaultProcessor() {
        setupProcessor(using: settings.selectedProcessor)
    }
    
    /**
     Sets up the provided processor.
     
     Flext's processors can be defined in such a way that user's can specify
     various options (these are additional arguments passed to the `process()`
     function). While these options are entered by the user as strings of text,
     they can of course be any legitimate JavaScript value.
     
     To parse the option into its JavaScript value, Flext loads the JavaScript
     context for the processor and then evaluates the option within that
     context. The values are then saved to the `arguments` property so that they
     can be used when processing text.
     
     - Parameters:
        - processor: The processor to set up.
     */
    func setupProcessor(using processor: Processor) {
        setupProcessorTitle(processor.name)
        
        self.processor = processor
        self.arguments = [""]

        if self.processor.hasOptions {
            guard let context = self.processor.function?.context else { return }
            
            for option in self.processor.options {
                var javascriptValue: JSValue? = nil
                
                if let value = option.value {
                    javascriptValue = context.evaluateScript(value)
                }
                
                if javascriptValue == nil {
                    self.arguments.append(JSValue(undefinedIn: self.processor.function?.context)!)
                } else {
                    self.arguments.append(javascriptValue!)
                }
            }
        }
    }
    
    /**
     Sets the processor's title.
     
     Flext's main interface displays the name of the selected processor in the
     editor as a button. As changes to this button will be animated by default,
     this method also includes a call to `self.view.layoutIfNeeded()` to force
     the change to happen without animation.
     
     - Parameters:
        - title: The name of the processor.
     */
    func setupProcessorTitle(_ title: String) {
        processorButton.setTitle(title, for: .normal)
        UIView.animate(withDuration: 0) { self.view.layoutIfNeeded() }
    }
    
    // MARK: - Text Views Setup
    
    /**
     Sets the margins for the text views used for the preview and the editor.
     
     By default, UIKit will inset `UITextView` objects. This creates visual
     inconsistency in Flext's interface where the edge of the text should be
     flush with the edge of the header and button elements. This method is a
     hack that reduces the default inset (the inset is not editable from
     Interface Builder and so must be changed programmatically).
     */
    func setupMargins() {
        let marginReduction = -(textPreview.textContainer.lineFragmentPadding)
        textPreview.textContainerInset.left = marginReduction
        textPreview.textContainerInset.right = marginReduction
        textEditor.textContainerInset.left = marginReduction
        textEditor.textContainerInset.right = marginReduction
    }

    /**
     Sets up preview hiding.
     
     One of the few 'power user' features of Flext is the fact that the
     'Preview' heading that appears to be a `UILabel` object is in fact a
     `UIButton` object. When a user taps on the button, the preview is hidden.

     Unfortunately, when Flext is laid out in the vertical split view, hiding
     the preview is not easy to do. Rather than engage in large scale
     refactoring of the user interface to provide a way for the preview to be
     hidden in the vertical split view, the 'solution' is to disable the button
     so that the button cannot be used.
     */
    func setupPreviewHiding() {
        if traitCollection.verticalSizeClass == .compact || traitCollection.horizontalSizeClass == .regular {
            previewHeading.isEnabled = false
        }
    }
    
    /**
     Sets up the text editor.
     
     This method sets up the text editor, including restoring text that may have
     been in the editor prior to the app being closed.
     */
    func setupTextEditor() {
        enteredText.editor = textEditor as? TextViewWithPlaceholder
        
        if enteredText.hasPreviousValue {
            enteredText.editor?.replaceText(with: enteredText.previousValue)
        }
    }

    // MARK: - Processor Execution
    
    /**
     Runs the active processor.
     
     This method runs the text in the editor through the active processor and
     updates the text preview. If the active processor is used, the value of the
     `enteredText` will be inserted as the first argument in the `arguments`
     property nad then run passed to the active processor's function.
     
     A guard is necessary in case the text editor is displaying the placeholder
     text.
     */
    func runProcessor() {
        guard let text = enteredText.value else { return }
        
        if text.isEmpty {
            textPreview.text = text
        } else {
            arguments[0] = text
            guard let result = processor.function?.call(withArguments: arguments) else { return }
            textPreview.text = result.toString()
        }
    }
    
    // MARK: - UI Adjustments

    /**
     Gets the height of the keyboard that covers the app's frame.
     
     For the app proper, this value is merely the height of the keyboard.
     However, in the action extension subclass of this view controller, it is
     possible that the keyboard covers only a portion of the extension UI (this
     is the case when the extension is running on an iPad).
     
     - Parameters:
        - keyboardValue: a value representing the 'keyboard' extracted when
                         processing the `keyboardWillChangeFrameNotification`.
     */
    func visibleKeyboardHeight(of keyboardValue: NSValue) -> CGFloat? {
        return keyboardValue.cgRectValue.size.height
    }
    
    /**
     Adjusts the height of the text preview and editor views.
     
     The visual design of Flext splits the main editing screen in half, using
     half for the editor and half for the preview (and controls).
     
     While it would be possible (at least in the horizontal split view) for
     Flext to merely shrink the amount of space available to the text editor
     when the onscreen keyboard is shown, this would result in an unbalanced
     design with a large amount of space devoted to the preview and a small
     amount of space devoted to the editor. An alternative (and probably safe)
     approach, would be to assume the onscreen display was always visible.
     However, when this was not true, a similar problem would result.
     
     The solution is to adjust the heights of the text preview and editor views
     when any event occurs that changes the keyboard frame.
     */
    @objc func adjustTextEditorHeight(notification: Notification) {
        if notification.name == UIResponder.keyboardWillChangeFrameNotification {
            guard let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            guard let keyboardHeight = visibleKeyboardHeight(of: keyboardRect) else { return }

            if traitCollection.verticalSizeClass != .compact && traitCollection.horizontalSizeClass != .regular {
                appContainerBottomConstraint.constant = keyboardHeight * 0.6
                textEditor.contentInset.bottom = keyboardHeight * 0.4
            } else {
                appContainerBottomConstraint.constant = keyboardHeight
            }
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            appContainerBottomConstraint.constant = .zero
            textEditor.contentInset.bottom = .zero
        }

        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        view.setNeedsLayout()
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    
    /**
     Scrolls the preview.
     
     Although the text in the preview cannot be edited, it can be scrolled. The
     difficulty with scrolling the preview in sync with the editor is that the
     number of characters in the preview will often not match the number of
     characters in the editor (e.g. because the active processor inserted
     characters).
     
     This method's solution is in three parts. If the cursor is at the beginning
     of the editor, the text preview is scrolled to show the beginning. If the
     cursor is at the end of the editor, the text preview is scrolled to show
     the end. In the third situation, the ratio of the cursor index within the
     entered text to the total number of characters in the entered text is used
     to calculate an index in the text preview. The preview is then scrolled to
     show this point.
     */
    func scrollPreview() {
        guard let value = enteredText.value else { return }
        guard let textView = enteredText.editor else { return }
        guard let selection = textView.selectedTextRange else { return }
        guard value.count > 0 else { return }
        
        var caret: CGRect
        
        switch selection.end {
        case textView.beginningOfDocument:
            caret = textPreview.caretRect(for: textPreview.beginningOfDocument)
        case textView.endOfDocument:
            caret = textPreview.caretRect(for: textPreview.endOfDocument)
        default:
            let positionRatio = Double(textView.offset(from: textView.beginningOfDocument, to: selection.end)) / Double(value.utf16.count)
            let equivalentIndex = Int((Double(textPreview.text.utf16.count) * positionRatio).rounded(.up))
            let equivalentPosition = textPreview.position(from: textPreview.beginningOfDocument, offset: equivalentIndex)
            
            caret = textPreview.caretRect(for: equivalentPosition ?? textPreview.endOfDocument)
        }
        
        textPreview.scrollRectToVisible(caret, animated: false)
    }
    
    /**
     Toggles the visibility of the preview.
     
     This method adds a constraint of zero height to text preview if the preview
     is to be hidden or removes this height constraint if the preview is to be
     made visible.
     
     - Parameters:
        - sender: The button that triggered the toggle (this should be the
                  'hidden' preview button.
     */
    @IBAction func togglePreview(_ sender: UIButton? = nil) {
        if previewIsHidden {
            UIView.animate(withDuration: 0.5) {
                self.textPreview.removeConstraint(self.textPreviewHeightConstraint)
                self.appContainer.distribution = .fillEqually
                self.appContainer.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.appContainer.distribution = .fill
                self.textPreview.addConstraint(self.textPreviewHeightConstraint)
                self.appContainer.layoutIfNeeded()
            }
        }
    }

    // MARK: - Copying, Pasting and Resetting
    
    /**
     Interacts with the text.
     
     This method is used by the reset/copy/paste controls to interact with
     the preview text.
     
     - Parameters:
        - sender: The button that triggered the toggle (this should be one of
                  the buttons in the segmented control).
     */
    @IBAction func interactWithText(_ sender: UISegmentedControl) {
        guard enteredText.hasValue else { return }
        
        switch Button(rawValue: sender.selectedSegmentIndex) {
        case .reset:
            enteredText.editor?.replaceText(with: "", allowEmpty: true)
        case .copy:
            UIPasteboard.general.string = textPreview.text
        case .paste:
            guard let paste = UIPasteboard.general.string else { return }
            enteredText.editor?.appendText(with: paste)
        default:
            break
        }
    }
}

// MARK: - Text View Delegate

extension EditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        runProcessor()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        scrollPreview()
    }
}

// MARK: - Presentation Controller Delegate

extension EditorViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        returnToEditor()
    }
}
