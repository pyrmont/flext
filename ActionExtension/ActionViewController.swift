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

// MARK: - Action View Controller Definition

class ActionViewController: EditorViewController {
    enum DataType {
        case text, webpage
    }

    @IBOutlet var processorTitle: UINavigationItem!
    
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
    
    override func setupUserActivity() {
        return
    }
    
    // MARK: - Processor Setup
    
    override func setupDefaultProcessor() {
         let selectedIndex = UserDefaults.standard.integer(forKey: "selectedIndex")
         
         if selectedIndex < settings.enabledProcessors.count {
             self.selectedIndex = selectedIndex
         } else {
             self.selectedIndex = 0
             UserDefaults.standard.set(0, forKey: "selectedIndex")
         }
         
         setupProcessor(using: settings.enabledProcessors.at(self.selectedIndex)!)
    }
    
    override func setupProcessorTitle(_ title: String) {
        self.processorTitle.title = title
    }
    
    // MARK: - Text Editor Setup
    
    override func setupPreviewHiding() {
        return
    }
    
    // MARK: - Returning

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
        setupDefaultProcessor()
        runProcessor()
    }
    
    // MARK: - UI Adjustments
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        return
    }
    
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
