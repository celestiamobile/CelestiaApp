//
// ScriptController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Cocoa

import CelestiaCore

class ScriptController: NSObject {
    @IBOutlet private weak var scriptMenu: NSMenu!

    static let supportedFileExtensions = ["cel", "celx"]

    private var savedScripts: [Script] = []

    private var lastScriptPath: String?

    @IBAction private func runScript(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ScriptController.supportedFileExtensions
        panel.allowsMultipleSelection = false
        let result = panel.runModal()
        if result == .OK, let url = panel.url {
            runScript(at: url.path)
        }
    }

    @IBAction func rerunScript(_ sender: Any) {
        if let path = lastScriptPath {
            runScript(at: path)
        }
    }

    func runScript(at path: String) {
        guard AppDelegate.shared.isCelestiaLoaded else { return }

        lastScriptPath = path
        CelestiaViewController.urlToRun = URL(fileURLWithPath: path)
        AppDelegate.shared.celestiaViewController.checkNeedOpeningURL()
    }

    func buildScriptMenu() {
        let scripts = readScripts()

        for i in 0..<scripts.count {
            let menuItem = NSMenuItem(title: scripts[i].title, action: #selector(scriptInvoked(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.tag = i
            scriptMenu.addItem(menuItem)
        }

        savedScripts = scripts
    }

    @objc private func scriptInvoked(_ sender: NSMenuItem) {
        runScript(at: savedScripts[sender.tag].filename)
    }
}
