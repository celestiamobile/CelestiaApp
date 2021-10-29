//
// BrowserViewController.swift
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

class BrowserViewController: NSViewController {
    @IBOutlet weak var tabView: NSTabView!

    @IBOutlet private var solarSystemTree: NSTreeController!
    @IBOutlet private var starTree: NSTreeController!
    @IBOutlet private var dsoTree: NSTreeController!

    private lazy var sol = solBrowserRoot
    private lazy var stars = starBrowserRoot
    private lazy var dso = dsoBrowserRoot

    private var currentTree: NSTreeController {
        return [
            "solarSystem" : solarSystemTree,
            "star" : starTree,
            "dso" : dsoTree,
        ][tabView.selectedTabViewItem?.identifier as! String]!
    }

    private var currentSelection: Selection? {
        guard let object = currentTree.selectedObjects.first as? BrowserItem else { return nil }

        return Selection(item: object)
    }

    private let core: AppCore = AppCore.shared
    private lazy var universe: Universe = self.core.simulation.universe

    override func viewDidLoad() {
        super.viewDidLoad()

        solarSystemTree.content = NSArray(array: [sol].compactMap { $0 })
        starTree.content = NSArray(array: stars.children)
        dsoTree.content = NSArray(array: dso.children)
    }

    @IBAction private func commonAction(_ sender: NSButton) {
        if let sel = currentSelection {
            let tag = sender.tag
            if sender.tag == 0 {
                core.selectAsync(sel)
            } else {
                core.selectAndCharEnterAsync(sel, char: Int8(tag))
            }
        }
    }

    @IBAction private func doubleClick(_ sender: NSOutlineView) {
        let clickedRow = sender.clickedRow
        guard clickedRow >= 0 else { return }

        if let item = (sender.item(atRow: clickedRow) as? NSTreeNode)?.representedObject as? BrowserItem, let sel = Selection(item: item) {
            core.selectAndCharEnterAsync(sel, char: 103)
        }
    }
}

extension BrowserViewController: NSTabViewDelegate {
}

