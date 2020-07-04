//
// SplashWindow.swift
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

private var dataDirectoryURL: UniformedURL!
private var configFileURL: UniformedURL!

class SplashViewController: NSViewController {
    @IBOutlet private weak var versionLabel: NSTextField!
    @IBOutlet private weak var statusLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let shortVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        versionLabel.stringValue = shortVersion

        dataDirectoryURL = currentDataDirectory()
        configFileURL = currentConfigFile()

        setupResourceDirectory()

        let core = CelestiaAppCore.shared
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            // create a context in case it's needed by Celestia
            let context = NSOpenGLContext(format: NSOpenGLPixelFormat(), share: nil)
            context?.makeCurrentContext()
            let result = core.startSimulation(configFileName: configFileURL.url.path, extraDirectories: [extraDirectory].compactMap{$0?.path}, progress: { (status) in
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = status
                }
            })
            NSOpenGLContext.clearCurrentContext()
            DispatchQueue.main.async {
                if !result {
                    self.view.window?.close()
                    let alert = NSAlert()
                    alert.messageText = CelestiaString("Loading Celestia failed…", comment: "")
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: CelestiaString("Choose Config File", comment: ""))
                    alert.addButton(withTitle: CelestiaString("Quit", comment: ""))
                    if alert.runModal() == .alertFirstButtonReturn {
                        AppDelegate.shared.showChangeConfigFile(launchFailure: true)
                        return
                    }
                    NSApp.terminate(nil)
                    return
                }
                AppDelegate.shared.scriptController.buildScriptMenu()
                AppDelegate.shared.bookmarkController.readBookmarksFromDisk()
                AppDelegate.shared.bookmarkController.buildBookmarkMenu()
                let wc = self.storyboard?.instantiateController(withIdentifier: "Main") as! NSWindowController
                wc.showWindow(nil)
                self.view.window?.close()
            }
        }
    }

    func setupResourceDirectory() {
        FileManager.default.changeCurrentDirectoryPath(dataDirectoryURL.url.path)
        CelestiaAppCore.setLocaleDirectory(dataDirectoryURL.url.path + "/locale")
    }
}

class SplashWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: true)
        backgroundColor = .clear
        alphaValue = 1
        isOpaque = false
        hasShadow = false
        isMovableByWindowBackground = true

        let frame = screen!.frame

        setFrameOrigin(CGPoint(x: (frame.width - contentRect.width) / 2, y: (frame.height - contentRect.height) / 2))
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        isReleasedWhenClosed = true
    }

}

class SplashImageView: NSImageView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}
