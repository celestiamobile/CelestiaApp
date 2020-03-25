//
//  AppDelegate.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/9.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate {
        return NSApp.delegate as! AppDelegate
    }

    @IBOutlet var scriptController: ScriptController!
    @IBOutlet var bookmarkController: BookmarkController!

    var celestiaViewController: CelestiaViewController? {
        return NSApp.windows.first?.contentView?.nextResponder as? CelestiaViewController
    }

    lazy var core = CelestiaAppCore.shared

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Migrator.tryToMigrate()
        CelestiaAppCore.setLocaleDirectory(defaultDataDirectory.path + "/locale")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return core.isInitialized
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if core.isInitialized {
            core.storeUserDefaults()
            bookmarkController.storeBookmarksToDisk()
        }
    }

    @IBAction func captureMovie(_ sender: Any) {
        celestiaViewController?.showVideoCapture()
    }

    @IBAction func screenshot(_ sender: Any) {
        celestiaViewController?.saveScreenshot()
    }

    @IBAction func forward(_ sender: Any) {
        celestiaViewController?.forward()
    }

    @IBAction func back(_ sender: Any) {
        celestiaViewController?.back()
    }

    @IBAction func commonMenuItemHandler(_ sender: NSMenuItem) {
        celestiaViewController?.handleMenuItem(sender)
    }

    @IBAction func presentBrowser(_ sender: NSMenuItem) {
        celestiaViewController?.showBrowser()
    }

    @IBAction func presentEclipseFinder(_ sender: NSMenuItem) {
        celestiaViewController?.showEclipseFinder()
    }

    @IBAction func presentSetting(_ sender: NSMenuItem) {
        celestiaViewController?.showSetting()
    }

    @IBAction func presentGoto(_ sender: NSMenuItem) {
        celestiaViewController?.showGoto()
    }

    @IBAction func presentSetTime(_ sender: NSMenuItem) {
        celestiaViewController?.showSetTime()
    }

    @IBAction func presentHelp(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "https://en.wikibooks.org/wiki/Celestia")!)
    }

    @IBAction func presentGLInfo(_ sender: NSMenuItem) {
        if let existing = NSApp.findWindow(type: GLInfoViewController.self) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let vc = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "GLInfo") as! NSViewController
        let panel = NSPanel(contentViewController: vc)
        panel.styleMask = [panel.styleMask, .utilityWindow]
        panel.makeKeyAndOrderFront(self)
    }

    @IBAction func changeConfigFile(_ sender: Any) {
        showChangeConfigFile(launchFailure: false)
    }

    func showChangeConfigFile(launchFailure: Bool) {
        if let existing = NSApp.findWindow(type: ConfigSelectionViewController.self) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let vc = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "ConfigSelectionWindow") as! ConfigSelectionViewController
        vc.launchFailure = launchFailure
        let panel = NSPanel(contentViewController: vc)
        panel.styleMask = panel.styleMask.subtracting([.resizable, .miniaturizable])
        if launchFailure {
            panel.styleMask = panel.styleMask.subtracting(.closable)
        }
        panel.makeKeyAndOrderFront(self)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        scriptController.runScript(at: filename)
        return true
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
