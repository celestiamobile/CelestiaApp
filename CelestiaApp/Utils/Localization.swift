//
//  Localization.swift
//  Celestia
//
//  Created by Levin Li on 2020/5/7.
//  Copyright © 2020 李林峰. All rights reserved.
//

import AppKit

extension NSButtonCell: IBLocalizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}


extension NSTextFieldCell: IBLocalizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
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

extension NSWindow: IBLocalizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

extension NSTableColumn: IBLocalizable {
    public func localize() {
        title = CelestiaString(title, comment: "")
    }
}

public func SetupLocalizationSwizzling() {
    SwizzleLocalizableClass(NSButtonCell.self)
    SwizzleLocalizableClass(NSTextFieldCell.self)
    SwizzleLocalizableClass(NSBox.self)
    SwizzleLocalizableClass(NSTabViewItem.self)
    SwizzleLocalizableClass(NSMenuItem.self)
    SwizzleLocalizableClass(NSMenu.self)
    SwizzleLocalizableClass(NSWindow.self)
    SwizzleLocalizableClass(NSTableColumn.self)
}
