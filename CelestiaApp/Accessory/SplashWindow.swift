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

let celestiaLoadingStatusNotificationName = Notification.Name("CelestiaLoadingStatus")
let celestiaLoadingStatusNotificationKey = "CelestiaLoadingStatusKey"
let celestiaLoadingFinishedNotificationName = Notification.Name("CelestiaLoadingFinished")

private var celestiaWC: NSWindowController? = {
    return NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Main") as? NSWindowController
}()

class SplashViewController: NSViewController {
    @IBOutlet private weak var versionLabel: NSTextField!
    @IBOutlet private weak var statusLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let shortVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        versionLabel.stringValue = shortVersion

        // Load thw window so we have a rendering context
        _ = celestiaWC?.window

        NotificationCenter.default.addObserver(self, selector: #selector(loadingStatusUpdate(_:)), name: celestiaLoadingStatusNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinished(_:)), name: celestiaLoadingFinishedNotificationName, object: nil)
    }

    @objc private func loadingStatusUpdate(_ notification: Notification) {
        guard let status = notification.userInfo?[celestiaLoadingStatusNotificationKey] as? String else { return }

        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.stringValue = status
        }
    }

    @objc private func loadingFinished(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.view.window?.close()
            celestiaWC?.showWindow(nil)
        }
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
