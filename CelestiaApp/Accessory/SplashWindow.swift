//
//  SplashWindow.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

private func createExtraDirectory() -> String? {
    let mainDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let extraDirectory = "\(mainDirectory)/extras"
    do {
        try FileManager.default.createDirectory(atPath: extraDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch _ {
        return nil
    }
    return extraDirectory
}

class SplashViewController: NSViewController {
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!

    private let resourceFolderName = "CelestiaResources"

    override func viewDidLoad() {
        super.viewDidLoad()

        let shortVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        versionLabel.stringValue = shortVersion

        setupResourceDirectory()

        DispatchQueue.global().async { [weak self] in
            let result = AppDelegate.shared.core.startSimulation(configFileName: nil, extraDirectories: [createExtraDirectory()].compactMap{$0}, progress: { (status) in
                DispatchQueue.main.async {
                    self?.statusLabel.stringValue = status
                }
            })
            DispatchQueue.main.async {
                if !result {
                    NSAlert.fatalError(text: NSLocalizedString("Error loading data files. Celestia will now quit.", comment: ""))
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

        var resourceDirectories = [String]()

        let defaultPath = Bundle.main.resourcePath!.appending("/\(resourceFolderName)")
        var isDirectory: ObjCBool = false
        if fm.fileExists(atPath: defaultPath, isDirectory: &isDirectory), isDirectory.boolValue {
            resourceDirectories.append(defaultPath)
        }

        guard let first = resourceDirectories.first else {
            NSAlert.fatalError(text: NSLocalizedString("It appears that the \"CelestiaResources\" directory has not been properly installed in the correct location as indicated in the installation instructions. \n\nPlease correct this and try again.", comment: ""))
        }

        FileManager.default.changeCurrentDirectoryPath(first)
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
