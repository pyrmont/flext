//
//  ActionViewController.swift
//  ActionExtension
//
//  Created by Michael Camilleri on 19/8/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit
import JavaScriptCore
import MobileCoreServices

/**
 Displays the action extension.

 Flext offers an action extension for plain text and webpages. Because of the
 similarities, this class draws most of its functionality from its superclass,
 `EditorViewController`.
 */
class ActionViewController: EditorViewController {

    // MARK: - DataType Enum

    /**
     Represents the datatypes that are supported by the extension.
     */
    enum DataType {
        case text, webpage
    }

    // MARK: - IB Outlet Values

    @IBOutlet var processorTitle: UINavigationItem!

    // MARK: - Properties

    var selectedIndex: Int!

    // MARK: - Controller Loading

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let items = self.extensionContext?.inputItems as? [NSExtensionItem] else { return }
        guard let item = items.first else { return }
        guard let provider = item.attachments?.first else { return }

        if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
            process(provider, as: .webpage)
        } else if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
            process(provider, as: .text)
        }
    }

    // MARK: - Data Processing

    /**
     Processes the data sent to the extension.

     The mechanism for exposing data to extensions is to wrap the data in a
     `NSItemProvider` object. Depending on the data type, this method extracts
     the data from that object.

     - Parameters:
        - provider: The object wrapping the data.
        - dataType: The type of data.
     */
    func process(_ provider: NSItemProvider, as dataType: DataType) {
        switch dataType {
        case .text:
            provider.loadItem(forTypeIdentifier: kUTTypeText as String) { [weak self] (providedText, error) in
                OperationQueue.main.addOperation {
                    self?.enteredText.editor?.replaceText(with: providedText as? String)
                }
            }
        case .webpage:
            provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (providedDictionary, error) in
                guard let itemDictionary = providedDictionary as? NSDictionary else { return }
                guard let values = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                OperationQueue.main.addOperation {
                    self?.enteredText.editor?.replaceText(with: values["text"] as? String)
                }
            }
        }
    }

    // MARK: - State Restoration

    /**
     Skips setting up state restoration.

     While the editor in the main app supports state restoration, the action
     extension does not. This override prevents the activity from being set up.
     */
    override func setupUserActivity() {
        return
    }

    // MARK: - Listener Setup

    /**
     Skips responding to changes to the app's traits.

     While the editor in the main app uses changes in the app's traits to handle
     the preview hiding, this is not relevant in the action extension. This
     override prevents these responses.
     */
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        return
    }

    // MARK: - Processor Setup

    override func selectedProcessor() -> Processor {
        guard selectedIndex == nil else {
            if selectedIndex >= settings.enabledProcessors.count {
                selectedIndex = 0
                UserDefaults.standard.set(selectedIndex, forKey: "selectedIndex")
            }
            return settings.enabledProcessors[selectedIndex]
        }

        let savedIndex = UserDefaults.standard.integer(forKey: "selectedIndex")

        if savedIndex < settings.enabledProcessors.count {
            selectedIndex = savedIndex
        } else {
            selectedIndex = 0
            UserDefaults.standard.set(selectedIndex, forKey: "selectedIndex")
        }

        return settings.enabledProcessors[selectedIndex]
    }

    /**
     Sets the active processor title.

     The processor title in the action extension is displayed in a navigation
     bar at the top of the extension rather than in a button in the main
     interface. This sets the title in the correct element.
     */
    override func setupProcessorTitle(_ title: String) {
        self.processorTitle.title = title
    }

    // MARK: - Text Editor Setup

    /**
     Skips setting preview hidding.

     While the editor in the main app supports hiding of the preview, the
     action extension does not. This override prevents the preview hiding from
     being set up.
     */
    override func setupPreviewHiding() {
        return
    }

    // MARK: - Returning

    /**
     Inserts the processed text for return to its context.
     */
    @IBAction func insert() {
        guard let processedText = textPreview.text else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        let extensionItem = NSExtensionItem()
        let processedDictionary = [NSExtensionJavaScriptFinalizeArgumentKey : ["text": processedText]]
        extensionItem.attachments = [NSItemProvider(item: processedDictionary as NSSecureCoding, typeIdentifier: String(kUTTypePropertyList))]
        self.extensionContext?.completeRequest(returningItems: [extensionItem], completionHandler: nil)
    }

    // MARK: - Segues

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard UserDefaults.standard.integer(forKey: "selectedIndex") != selectedIndex else { return }
        setupProcessor()
        runProcessor()
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
    override func visibleKeyboardHeight(of keyboardValue: NSValue) -> CGFloat? {
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        // This is a hacky resolution to getting this to work on the iPad. Why
        // is the magic number 50? Your guess is as good as mine.
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let viewBottomY = view.window?.frame.maxY, keyboardViewEndFrame.minY < viewBottomY else { return nil }
            return (viewBottomY - keyboardViewEndFrame.minY) + 50
        } else {
            return keyboardViewEndFrame.height
        }
    }
}
