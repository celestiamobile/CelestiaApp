//
// ConfigSelectionViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Cocoa

class ConfigSelectionViewController: NSViewController {

    @IBOutlet private weak var cancelButton: NSButton!
    @IBOutlet private weak var configPathControl: NSPathControl!
    @IBOutlet private weak var dataPathControl: NSPathControl!

    var launchFailure: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        configPathControl.url = currentConfigFile().url
        dataPathControl.url = currentDataDirectory().url

        if launchFailure {
            cancelButton.title = CelestiaString("Quit", comment: "")
        } else {
            cancelButton.title = CelestiaString("Cancel", comment: "")
        }
    }

    @IBAction func cancel(_ sender: Any) {
        if launchFailure {
            NSApp.terminate(nil)
        } else {
            view.window?.close()
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
                dataBookmark = try dataDir.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
            } catch let error {
                NSAlert(error: error).runModal()
                return
            }
        }

        if configFile == defaultConfigFile {
            configBookmark = nil
        } else {
            do {
                configBookmark = try configFile.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
            } catch let error {
                NSAlert(error: error).runModal()
                return
            }
        }

        saveDataDirectory(dataBookmark)
        saveConfigFile(configBookmark)
        NSApp.terminate(nil)

        NSWorkspace.shared.launchApplication(withBundleIdentifier: Bundle.app.bundleIdentifier!, options: .async, additionalEventParamDescriptor: nil, launchIdentifier: nil)
    }
}
