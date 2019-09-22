//
//  SplashWindow.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class SplashViewController: NSViewController {
    @IBOutlet private weak var versionLabel: NSTextField!
    @IBOutlet private weak var statusLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let shortVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        versionLabel.stringValue = shortVersion

        setupResourceDirectory()

        let core = AppDelegate.shared.core
        DispatchQueue.global().async { [weak self] in
            // create a context in case it's needed by Celestia
            let context = NSOpenGLContext(format: NSOpenGLPixelFormat(), share: nil)
            context?.makeCurrentContext()
            let result = core.startSimulation(configFileName: currentConfigFile().path, extraDirectories: [extraDirectory].compactMap{$0?.path}, progress: { (status) in
                DispatchQueue.main.async {
                    self?.statusLabel.stringValue = status
                }
            })
            NSOpenGLContext.clearCurrentContext()
            DispatchQueue.main.async {
                if !result {
                    self?.view.window?.close()
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Celestia failed to load data files.", comment: "")
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: NSLocalizedString("Choose Configuration File", comment: ""))
                    alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
                    if alert.runModal() == .alertFirstButtonReturn {
                        AppDelegate.shared.showChangeConfigFile(launchFailure: true)
                        return
                    }
                    NSApp.terminate(nil)
                    return
                }
                AppDelegate.shared.scriptController.buildScriptMenu()
                AppDelegate.shared.bookmarkController.readBookmarks()
                let wc = self?.storyboard?.instantiateController(withIdentifier: "Main") as! NSWindowController
                wc.showWindow(nil)
                self?.view.window?.close()
            }
        }
    }

    func setupResourceDirectory() {
        let fm = FileManager.default
        fm.changeCurrentDirectoryPath(currentDataDirectory().path)
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
