//
//  NSAlert.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

extension NSAlert {
    class func fatalError(text: String) -> Never {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Fatal Error", comment: "")
        alert.informativeText = text
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
        NSApp.terminate(nil)
        Swift.fatalError()
    }

    class func warning(message: String, text: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
    }

    class func selection(message: String, selections: [String]) -> Int? {
        let alert = NSAlert()
        alert.messageText = message

        let popup = NSPopUpButton(frame: CGRect(x: 0, y: 0, width: 180, height: 20), pullsDown: false)
        popup.addItems(withTitles: selections)
        popup.sizeToFit()

        alert.accessoryView = popup
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.layout()
        if alert.runModal() != .alertFirstButtonReturn {
            return nil
        }
        return popup.indexOfSelectedItem
    }

}
