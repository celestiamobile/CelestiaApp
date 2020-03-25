//
//  BrowserViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/10.
//  Copyright © 2019 李林峰. All rights reserved.
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

    private var currentSelection: CelestiaSelection? {
        guard let object = currentTree.selectedObjects.first as? CelestiaBrowserItem else { return nil }

        return CelestiaSelection(item: object)
    }

    private let core: CelestiaAppCore = CelestiaAppCore.shared
    private lazy var universe: CelestiaUniverse = self.core.simulation.universe

    override func viewDidLoad() {
        super.viewDidLoad()

        solarSystemTree.content = NSArray(array: [sol])
        starTree.content = NSArray(array: stars.children)
        dsoTree.content = NSArray(array: dso.children)
    }

    @IBAction private func commonAction(_ sender: NSButton) {
        if let sel = currentSelection {
            core.simulation.selection = sel
            if sender.tag != 0 {
                core.charEnter(Int8(sender.tag))
            }
        }
    }

    @IBAction private func doubleClick(_ sender: NSOutlineView) {
        let clickedRow = sender.clickedRow
        guard clickedRow >= 0 else { return }

        if let item = (sender.item(atRow: clickedRow) as? NSTreeNode)?.representedObject as? CelestiaBrowserItem, let sel = CelestiaSelection(item: item) {
            core.simulation.selection = sel
            core.charEnter(103)
        }
    }
}

extension BrowserViewController: NSTabViewDelegate {
}

