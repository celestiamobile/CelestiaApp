//
// SettingViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Cocoa

import CelestiaCore

struct PreferenceItem<Value> {
    let key: UserDefaultsKey
    let tag: Int
    let defaultValue: Value
}

class SettingViewController: NSViewController {
    private let core: CelestiaAppCore = CelestiaAppCore.shared

    private let preferenceItems = [
        PreferenceItem(key: .fullDPI, tag: 2000, defaultValue: true),
        PreferenceItem(key: .msaa, tag: 2001, defaultValue: false)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        scan(for: view)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        core.run { $0.storeUserDefaults() }
    }

    @objc private func activeMenuItem(_ sender: NSMenuItem) {
        let buttonTag = sender.tag / 10 * 10
        let value = sender.tag - buttonTag
        core.run { $0.setIntegerValue(value, forTag: buttonTag) }
    }

    @objc private func activeSlider(_ sender: NSSlider) {
        let value = sender.floatValue
        let tag = sender.tag
        core.run { $0.setFloatValue(value, forTag: tag) }
    }

    @objc private func activeButton(_ sender: NSButton) {
        let tag = sender.tag
        let on = sender.state == .on
        core.run { $0.setBoolValue(on, forTag: tag) }
    }

    @objc private func activePrefItemButton(_ sender: NSButton) {
        guard let prefItem = preferenceItems.first(where: { $0.tag == sender.tag }) else { return }

        UserDefaults.app[prefItem.key] = sender.state == .on
    }
}

extension SettingViewController {
    private func scan(for object: NSObject?) {
        guard let obj = object else { return }

        if let item = obj as? NSTabViewItem {
            scan(for: item.view)
            return
        }

        if let item = obj as? NSMenuItem, item.tag != 0 {
            item.target = self
            item.action = #selector(activeMenuItem(_:))
            return
        }

        if let item = obj as? NSSlider, item.tag != 0 {
            item.target = self
            item.action = #selector(activeSlider(_:))
            item.floatValue = core.floatValue(forTag: item.tag)
            return
        }

        if let tab = obj as? NSTabView {
            tab.tabViewItems.forEach { (item) in
                scan(for: item)
            }
            return
        }

        if let button = obj as? NSPopUpButton, button.tag != 0 {
            let selectedTag = core.integerValue(forTag: button.tag) + button.tag
            button.itemArray.forEach { (item) in
                if item.tag == selectedTag {
                    button.select(item)
                    item.state = .on
                } else {
                    item.state = .off
                }
                scan(for: item)
            }
            return
        }

        if let control = obj as? NSButton, control.tag != 0 {
            control.target = self
            if let prefItem = preferenceItems.first(where: { $0.tag == control.tag }) {
                control.action = #selector(activePrefItemButton(_:))
                control.state = UserDefaults.app[prefItem.key] ?? prefItem.defaultValue ? .on : .off
            } else {
                control.action = #selector(activeButton(_:))
                control.state = core.boolValue(forTag: control.tag) ? .on : .off
            }
            return
        }

        if let matrix = obj as? NSMatrix {
            matrix.cells.forEach { (item) in
                scan(for: item)
            }
            return
        }

        if let view = obj as? NSView {
            view.subviews.forEach { (item) in
                scan(for: item)
            }
            return
        }
    }
}
