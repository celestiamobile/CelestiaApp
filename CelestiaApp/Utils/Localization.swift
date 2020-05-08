//
//  Localization.swift
//  Celestia
//
//  Created by Levin Li on 2020/5/7.
//  Copyright © 2020 李林峰. All rights reserved.
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
