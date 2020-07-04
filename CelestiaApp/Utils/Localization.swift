//
// Localization.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import AppKit

extension NSButton: IBLocalizable {
    public func localize() {
        if self is NSPopUpButton { return }
        title = CelestiaString(title, comment: "")
    }
}

extension NSTextField: IBLocalizable {
    public func localize() {
        stringValue = CelestiaString(stringValue, comment: "")
    }
}

extension NSBox: IBLocalizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

extension NSTabViewItem: IBLocalizable {
    public func localize() {
        label = CelestiaString(label, comment: "")
    }
}

extension NSMenuItem: IBLocalizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

extension NSMenu: IBLocalizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

extension NSViewController: IBLocalizable {
    public func localize() {
        guard let unlocalized = title else { return }
        title = CelestiaString(unlocalized, comment: "")
    }
}

extension NSTableColumn: IBLocalizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

public func SetupLocalizationSwizzling() {
    SwizzleLocalizableClass(NSButton.self)
    SwizzleLocalizableClass(NSTextField.self)
    SwizzleLocalizableClass(NSBox.self)
    SwizzleLocalizableClass(NSTabViewItem.self)
    SwizzleLocalizableClass(NSMenuItem.self)
    SwizzleLocalizableClass(NSMenu.self)
    SwizzleLocalizableClass(NSViewController.self)
    SwizzleLocalizableClass(NSTableColumn.self)
}
