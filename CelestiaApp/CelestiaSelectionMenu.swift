//
//  CelestiaSelectionMenu.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/10.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

extension NSMenuItem {
    convenience init(title string: String, tag: Int, keyEquivalent charCode: String) {
        self.init(title: string, action: nil, keyEquivalent: charCode)
        self.tag = tag
    }
}

extension CelestiaSelection {
    static let nameItem = NSMenuItem(title: NSLocalizedString("Object", comment: ""), tag: 0, keyEquivalent: "")
    static let go = NSMenuItem(title: NSLocalizedString("Go", comment: ""), tag: 103, keyEquivalent: "g")
    static let follow = NSMenuItem(title: NSLocalizedString("Follow", comment: ""), tag: 102, keyEquivalent: "f")
    static let orbitSync = NSMenuItem(title: NSLocalizedString("Orbit Synchronously", comment: ""), tag: 121, keyEquivalent: "y")
    static let lockPhase = NSMenuItem(title: NSLocalizedString("Lock Phase", comment: ""), tag: 58, keyEquivalent: ":")
    static let chase = NSMenuItem(title: NSLocalizedString("Chase", comment: ""), tag: 34, keyEquivalent: "\"")

    static let center = NSMenuItem(title: NSLocalizedString("Center", comment: ""), tag: 99, keyEquivalent: "c")
    static let track = NSMenuItem(title: NSLocalizedString("Track", comment: ""), tag: 116, keyEquivalent: "t")

    static let markOrUnmark: NSMenuItem = {
        let item = NSMenuItem(title: NSLocalizedString("Mark/Unmark", comment: ""), tag: 16, keyEquivalent: "p")
        item.keyEquivalentModifierMask = .control
        return item
    }()
    static let web = NSMenuItem(title: NSLocalizedString("Show Web Info", comment: ""), tag: 102, keyEquivalent: "")

    static let nameGroup: [NSMenuItem] = [nameItem]
    static let actionGroup: [NSMenuItem] = [go,
                                            follow,
                                            orbitSync,
                                            lockPhase,
                                            chase]
    static let locationGroup: [NSMenuItem] = [center,
                                              track]
    static let otherGroup: [NSMenuItem] = [markOrUnmark,
                                           web]

    static let allGroups: [[NSMenuItem]] = [nameGroup, actionGroup, locationGroup, otherGroup]

    var menu: NSMenu? {
        if isEmpty { return nil }

        let menu = NSMenu(title: "")

        var items: [NSMenuItem] = []

        CelestiaSelection.nameItem.title = name

        for group in CelestiaSelection.allGroups {
            if !group.isEmpty {
                if !items.isEmpty {
                    items.append(.separator())
                }
                items += group
            }
        }

        menu.items = items
        return menu
    }
}
