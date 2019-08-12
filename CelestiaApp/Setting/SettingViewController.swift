//
//  SettingViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class SettingViewController: NSViewController {
    let core: CelestiaAppCore = AppDelegate.shared.core

    override func viewDidLoad() {
        super.viewDidLoad()

        scan(for: view)
    }

    @objc private func activeMenuItem(_ sender: NSMenuItem) {
        let buttonTag = sender.tag / 10 * 10
        let value = sender.tag - buttonTag
        core.setIntegerValue(value, forTag: buttonTag)
    }

    @objc private func activeSlider(_ sender: NSSlider) {
        core.setFloatValue(sender.floatValue, forTag: sender.tag)
    }

    @objc private func activeButton(_ sender: NSButton) {
        core.setBoolValue(sender.state == .on, forTag: sender.tag)
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
            control.action = #selector(activeButton(_:))
            control.state = core.boolValue(forTag: control.tag) ? .on : .off
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
