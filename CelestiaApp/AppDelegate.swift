//
// AppDelegate.swift
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

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

let apiPrefix = "https://celestia.mobi/api"

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate {
        return NSApp.delegate as! AppDelegate
    }

    var isCelestiaLoaded: Bool = false

    @IBOutlet var scriptController: ScriptController!
    @IBOutlet var bookmarkController: BookmarkController!

    lazy var celestiaViewController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Main") as! CelestiaViewController

    private lazy var core = AppCore.shared

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        #if !DEBUG
        AppCenter.start(withAppSecret: "APPCENTER-APP-ID", services: [
            Analytics.self,
            Crashes.self
        ])
        #endif

        Migrator.tryToMigrate()
    }

    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue else { return }
        CelestiaViewController.urlToRun = URL(string: urlString)

        guard isCelestiaLoaded else { return }
        celestiaViewController.checkNeedOpeningURL()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return core.isInitialized
    }

    @IBAction func forward(_ sender: Any) {
        guard isCelestiaLoaded else { return }

        celestiaViewController.forward()
    }

    @IBAction func back(_ sender: Any) {
        guard isCelestiaLoaded else { return }

        celestiaViewController.back()
    }

    @IBAction func commonMenuItemHandler(_ sender: NSMenuItem) {
        guard isCelestiaLoaded else { return }

        celestiaViewController.handleMenuItem(sender)
    }

    @IBAction func presentBrowser(_ sender: NSMenuItem) {
        guard isCelestiaLoaded else { return }

        celestiaViewController.showBrowser()
    }

    @IBAction func presentEclipseFinder(_ sender: NSMenuItem) {
        guard isCelestiaLoaded else { return }

        celestiaViewController.showEclipseFinder()
    }

    @IBAction func presentSetting(_ sender: NSMenuItem) {
        guard isCelestiaLoaded else { return }

        celestiaViewController.showSetting()
    }

    @IBAction func presentGoto(_ sender: NSMenuItem) {
        guard isCelestiaLoaded else { return }

        celestiaViewController.showGoto()
    }

    @IBAction func presentSetTime(_ sender: NSMenuItem) {
        guard isCelestiaLoaded else { return }

        celestiaViewController.showSetTime()
    }

    @IBAction func presentHelp(_ sender: NSMenuItem) {
        guard isCelestiaLoaded else { return }

        NSWorkspace.shared.open(URL(string: "https://en.wikibooks.org/wiki/Celestia")!)
    }

    @IBAction func presentGLInfo(_ sender: NSMenuItem) {
        guard isCelestiaLoaded else { return }

        AppDelegate.present(identifier: "GLInfo", customization: { window in
            window.styleMask = [window.styleMask, .utilityWindow]
        }) { () -> GLInfoViewController in
            return NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "GLInfo") as! GLInfoViewController
        }
    }

    @IBAction func changeConfigFile(_ sender: Any) {
        showChangeConfigFile(launchFailure: false)
    }

    func showChangeConfigFile(launchFailure: Bool) {
        AppDelegate.present(identifier: "ConfigSelection", customization: { window in
            window.styleMask = window.styleMask.subtracting(.closable)
        }) { () -> ConfigSelectionViewController in
            let vc = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "ConfigSelectionWindow") as! ConfigSelectionViewController
            vc.launchFailure = launchFailure
            return vc
        }
    }

    deinit {
        AppDelegate.clear(identifier: "GLInfo")
        AppDelegate.clear(identifier: "ConfigSelection")
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        CelestiaViewController.urlToRun = URL(fileURLWithPath: filename)

        guard isCelestiaLoaded else { return true }
        celestiaViewController.checkNeedOpeningURL()
        return true
    }

    private static var savedWindows: [String : NSWindow] = [:]

    static func present<VC: NSViewController>(identifier: String, tryToReuse: Bool = true, customization: (NSWindow) -> Void = { _ in }, vcProvider: () -> VC) {
        let window = NSApp.findWindow(type: VC.self)
        if let w = window {
            if tryToReuse && w.isVisible {
                w.makeKeyAndOrderFront(nil)
                return
            } else {
                w.close()
            }
        }

        let vc = vcProvider()
        let panel = NSPanel(contentViewController: vc)
        panel.hidesOnDeactivate = false
        customization(panel)
        savedWindows[identifier] = panel
        panel.makeKeyAndOrderFront(nil)
    }

    static func clear(identifier: String) {
        savedWindows[identifier] = nil
    }
}


extension NSApplication {
    func findWindow<ViewController: NSViewController>(type: ViewController.Type) -> NSWindow? {
        for window in windows {
            if window.contentViewController is ViewController {
                return window
            }
        }
        return nil
    }
}
