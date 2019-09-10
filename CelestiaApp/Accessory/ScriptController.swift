//
//  ScriptController.swift
//  Celestia
//
//  Created by 李林峰 on 2019/8/12.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

class ScriptController: NSObject {
    @IBOutlet private weak var scriptMenu: NSMenu!

    static let supportedFileExtensions = ["cel", "celx"]

    private var savedScripts: [CelestiaScript] = []

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
        lastScriptPath = path
        AppDelegate.shared.celestiaViewController?.runScript(at: path)
    }

    func buildScriptMenu() {
        var scripts = CelestiaScript.scripts(inDirectory: "scripts", deepScan: true)
        if let extraScriptsPath = extraScriptDirectory?.path {
            scripts += CelestiaScript.scripts(inDirectory: extraScriptsPath, deepScan: true)
        }
        scriptMenu.removeAllItems()

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
