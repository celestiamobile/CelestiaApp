//
//  ConfigSelectionWindowController.swift
//  Celestia
//
//  Created by Li Linfeng on 10/9/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class ConfigSelectionViewController: NSViewController {

    @IBOutlet private weak var cancelButton: NSButton!
    @IBOutlet private weak var configPathControl: NSPathControl!
    @IBOutlet private weak var dataPathControl: NSPathControl!

    var launchFailure: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        configPathControl.url = currentConfigFile()
        dataPathControl.url = currentDataDirectory()

        if launchFailure {
            cancelButton.title = NSLocalizedString("Quit", comment: "")
        } else {
            cancelButton.title = NSLocalizedString("Cancel", comment: "")
        }
    }

    @IBAction func cancel(_ sender: Any) {
        if launchFailure {
            NSApp.terminate(nil)
        } else {
            view.window?.performClose(nil)
        }
    }

    @IBAction func reset(_ sender: Any) {
        configPathControl.url = defaultConfigFile
        dataPathControl.url = defaultDataDirectory
    }

    @IBAction func confirm(_ sender: Any) {
        guard let dataDir = dataPathControl.url, let configFile = configPathControl.url else {
            // TODO: no input, show error
            return
        }
        var dataBookmark: Data?
        var configBookmark: Data?
        if dataDir == defaultDataDirectory {
            dataBookmark = nil
        } else {
            do {
                dataBookmark = try dataDir.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            } catch let error {
                NSAlert(error: error).runModal()
                return
            }
        }

        if configFile == defaultConfigFile {
            configBookmark = nil
        } else {
            do {
                configBookmark = try configFile.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            } catch let error {
                NSAlert(error: error).runModal()
                return
            }
        }

        saveDataDirectory(bookmark: dataBookmark)
        saveConfigFile(bookmark: configBookmark)
        NSApp.terminate(nil)

        NSWorkspace.shared.launchApplication(withBundleIdentifier: Bundle.main.bundleIdentifier!, options: .async, additionalEventParamDescriptor: nil, launchIdentifier: nil)
    }
}
