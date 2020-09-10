//
//  SplitViewController.swift
//  FlextMac
//
//  Created by Michael Camilleri on 1/9/20.
//  Copyright © 2020 Michael Camilleri. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    var processorListController: SplitProcessorListViewController!
    var editorController: SplitEditorViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        #if targetEnvironment(macCatalyst)
        self.primaryBackgroundStyle = .sidebar
        #endif

        for viewController in viewControllers {
            if let editorController = viewController as? SplitEditorViewController {
                self.editorController = editorController
            } else if let processorListController = (viewController as? UINavigationController)?.topViewController as? SplitProcessorListViewController{
                self.processorListController = processorListController
            }
        }

        processorListController.editor = editorController
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(selectNextProcessorMenuAction):
            return processorListController.hasNextProcessor
        case #selector(selectPreviousProcessorMenuAction):
            return processorListController.hasPreviousProcessor
        case #selector(resetInputMenuAction):
            guard let text = editorController.enteredText.value else { return false }
            return !text.isEmpty
        case #selector(copyOutputMenuAction):
            guard let text = editorController.enteredText.value else { return false }
            return !text.isEmpty
        default:
            break
        }

        return super.canPerformAction(action, withSender: sender)
    }

    override func validate(_ command: UICommand) {
        switch command.title {
        case "Favourite":
            guard let processor = processorListController.processor(at: processorListController.settings.selectedProcessorPath) else { break }
            if processor.isFavourited {
                command.title = "Unfavourite"
            }
        default:
            break
        }

        super.validate(command)
    }

    @IBAction func selectNextProcessorMenuAction() {
        processorListController.selectNextProcessor()
    }

    @IBAction func selectPreviousProcessorMenuAction() {
        processorListController.selectPreviousProcessor()
    }

    @IBAction func toggleFavouriteStatusMenuAction() {
        processorListController.toggleFavouriteStatus()
    }

    @IBAction func resetInputMenuAction() {
        editorController.resetInput()
    }

    @IBAction func copyOutputMenuAction() {
        editorController.copyOutput()
    }

    @IBAction func showHelpAddingMenuAction(_ command: UICommand) {
        let webpage = Webpage(title: command.title, sourceFile: "help_adding.md")
        showHelp(webpage)
    }

    @IBAction func showHelpRemovingMenuAction(_ command: UICommand) {
        let webpage = Webpage(title: command.title, sourceFile: "help_removing.md")
        showHelp(webpage)
    }

    @IBAction func showHelpWritingMenuAction(_ command: UICommand) {
        let webpage = Webpage(title: command.title, sourceFile: "help_writing.md")
        showHelp(webpage)
    }

    func showHelp(_ webpage: Webpage) {
        guard let storyboard = storyboard else { return }

        let webpageController = storyboard.instantiateViewController(identifier: "Webpage") as! WebpageViewController
        webpageController.webpage = webpage

        present(webpageController, animated: true)
    }
}
