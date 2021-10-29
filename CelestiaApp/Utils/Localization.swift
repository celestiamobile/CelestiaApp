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

extension NSButton: Localizable {
    public func localize() {
        if self is NSPopUpButton { return }
        title = CelestiaString(title, comment: "")
    }
}

extension NSTextField: Localizable {
    public func localize() {
        stringValue = CelestiaString(stringValue, comment: "")
    }
}

extension NSBox: Localizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

extension NSTabViewItem: Localizable {
    public func localize() {
        label = CelestiaString(label, comment: "")
    }
}

extension NSMenuItem: Localizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

extension NSMenu: Localizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

extension NSViewController: Localizable {
    public func localize() {
        guard let unlocalized = title else { return }
        title = CelestiaString(unlocalized, comment: "")
    }
}

extension NSTableColumn: Localizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

 func SetupLocalizationSwizzling() {
    LocalizationUtils.swizzleLocalizableClass(NSButton.self)
    LocalizationUtils.swizzleLocalizableClass(NSTextField.self)
    LocalizationUtils.swizzleLocalizableClass(NSBox.self)
    LocalizationUtils.swizzleLocalizableClass(NSTabViewItem.self)
    LocalizationUtils.swizzleLocalizableClass(NSMenuItem.self)
    LocalizationUtils.swizzleLocalizableClass(NSMenu.self)
    LocalizationUtils.swizzleLocalizableClass(NSViewController.self)
    LocalizationUtils.swizzleLocalizableClass(NSTableColumn.self)
}
