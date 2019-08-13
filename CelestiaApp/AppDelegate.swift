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

    lazy var core = CelestiaAppCore()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        core.storeUserDefaults()
        bookmarkController.storeBookmarks()
    }

    @IBAction func captureMovie(_ sender: Any) {
        celestiaViewController?.showVideoCapture()
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
        let wc = NSWindowController(windowNibName: "HelpWindow")
        wc.showWindow(self)
    }

    @IBAction func presentGLInfo(_ sender: NSMenuItem) {
        let vc = NSStoryboard(name: "Accessory", bundle: nil).instantiateController(withIdentifier: "GLInfo") as! NSViewController
        let panel = NSPanel(contentViewController: vc)
        panel.makeKeyAndOrderFront(self)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        scriptController.runScript(at: filename)
        return true
    }
}
