//
// NSAlert.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Cocoa

extension NSAlert {
    class func fatalError(text: String) -> Never {
        let alert = NSAlert()
        alert.messageText = CelestiaString("Fatal Error", comment: "")
        alert.informativeText = text
        alert.alertStyle = .critical
        alert.addButton(withTitle: CelestiaString("OK", comment: ""))
        alert.runModal()
        NSApp.terminate(nil)
        Swift.fatalError()
    }

    class func warning(message: String, text: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: CelestiaString("OK", comment: ""))
        alert.runModal()
    }

    class func confirm(message: String, text: String = "", window: NSWindow, handler: @escaping () -> Void = {}) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: CelestiaString("OK", comment: ""))
        alert.addButton(withTitle: CelestiaString("Cancel", comment: ""))
        alert.beginSheetModal(for: window) { (response) in
            guard response == .alertFirstButtonReturn else { return }
            handler()
        }
    }

    class func selection(message: String, selections: [String], window: NSWindow, handler: @escaping (Int) -> Void) {
        let alert = NSAlert()
        alert.messageText = message

        let popup = NSPopUpButton(frame: CGRect(x: 0, y: 0, width: 180, height: 20), pullsDown: false)
        popup.addItems(withTitles: selections)
        popup.sizeToFit()

        alert.accessoryView = popup
        alert.alertStyle = .warning
        alert.addButton(withTitle: CelestiaString("OK", comment: ""))
        alert.addButton(withTitle: CelestiaString("Cancel", comment: ""))
        alert.layout()
        alert.beginSheetModal(for: window) { (response) in
            guard response == .alertFirstButtonReturn else { return }
            handler(popup.indexOfSelectedItem)
        }
    }

    class func selection<T>(message: String, cases: [(value: T, description: String)], window: NSWindow, handler: @escaping (T, String) -> Void) {
        selection(message: message, selections: cases.map { $0.description }, window: window) { (item) in
            handler(cases[item].value, cases[item].description)
        }
    }
}
