//
//  BrowserViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/10.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

extension CelestiaDSOCatalog {
    subscript(index: Int) -> CelestiaDSO {
        get {
            return object(at: index)
        }
    }
}

public struct CelestiaDSOCatalogIterator: IteratorProtocol {
    private let catalog: CelestiaDSOCatalog
    private var index = 0

    public typealias Element = CelestiaDSO

    init(catalog: CelestiaDSOCatalog) {
        self.catalog = catalog
    }

    mutating public func next() -> CelestiaDSO? {
        defer { index += 1 }
        if index >= catalog.count {
            return nil
        }
        return catalog[index]
    }
}

extension CelestiaDSOCatalog: Sequence {
    public typealias Iterator = CelestiaDSOCatalogIterator

    public __consuming func makeIterator() -> CelestiaDSOCatalogIterator {
        return CelestiaDSOCatalogIterator(catalog: self)
    }
}

class BrowserViewController: NSViewController {
    @IBOutlet weak var tabView: NSTabView!

    @IBOutlet private var solarSystemTree: NSTreeController!
    @IBOutlet private var starTree: NSTreeController!
    @IBOutlet private var dsoTree: NSTreeController!

    private lazy var sol: CelestiaBrowserItem = {
        let sol = universe.find("Sol")
        return CelestiaBrowserItem(name: universe.starCatalog.starName(sol.star!), catEntry: sol.star!, provider: universe)
    }()

    private lazy var stars: CelestiaBrowserItem = {
        func updateAccumulation(result: inout [String : CelestiaBrowserItem], star: CelestiaStar) {
            let name = universe.starCatalog.starName(star)
            result[name] = CelestiaBrowserItem(name: name, catEntry: star, provider: universe)
        }

        let nearest = CelestiaStarBrowser(kind: .nearest, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
        let brightest = CelestiaStarBrowser(kind: .brightest, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
        let hasPlanets = CelestiaStarBrowser(kind: .starsWithPlants, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)

        let nearestName = NSLocalizedString("Nearest Stars", comment: "")
        let brightestName = NSLocalizedString("Brightest Stars", comment: "")
        let hasPlanetsName = NSLocalizedString("Stars With Planets", comment: "")
        let stars = CelestiaBrowserItem(name: nil, children: [
            nearestName : CelestiaBrowserItem(name: nearestName, children: nearest),
            brightestName : CelestiaBrowserItem(name: brightestName, children: brightest),
            hasPlanetsName : CelestiaBrowserItem(name: hasPlanetsName, children: hasPlanets),
        ])
        return stars
    }()

    private lazy var dso: CelestiaBrowserItem = {
        let typeMap = [
            "SB" : NSLocalizedString("Galaxies (Barred Spiral)", comment: ""),
            "S" : NSLocalizedString("Galaxies (Spiral)", comment: ""),
            "E" : NSLocalizedString("Galaxies (Elliptical)", comment: ""),
            "Irr" : NSLocalizedString("Galaxies (Irregular)", comment: ""),
            "Neb" : NSLocalizedString("Nebulae", comment: ""),
            "Glob" : NSLocalizedString("Globulars", comment: ""),
            "Clust" : NSLocalizedString("Open Clusters", comment: ""),
            "Unknown" : NSLocalizedString("Unknown", comment: ""),
        ]

        func updateAccumulation(result: inout [String : CelestiaBrowserItem], item: (key: String, value: [String : CelestiaBrowserItem])) {
            let fullName = typeMap[item.key]!
            result[fullName] = CelestiaBrowserItem(name: fullName, children: item.value)
        }

        let prefixes = ["SB", "S", "E", "Irr", "Neb", "Glob", "Clust"]

        var tempDict = prefixes.reduce(into: [String : [String : CelestiaBrowserItem]]()) { $0[$1] = [String : CelestiaBrowserItem]() }

        let catalog = universe.dsoCatalog
        catalog.forEach({ (dso) in
            let matchingType = prefixes.first(where: {dso.type.hasPrefix($0)}) ?? "Unknown"
            let name = catalog.dsoName(dso)
            tempDict[matchingType]![name] = CelestiaBrowserItem(name: name, catEntry: dso, provider: universe)
        })

        let results = tempDict.reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
        return CelestiaBrowserItem(name: nil, children: results)
    }()

    private var currentTree: NSTreeController {
        return [
            "solarSystem" : solarSystemTree,
            "star" : starTree,
            "dso" : dsoTree,
        ][tabView.selectedTabViewItem?.identifier as! String]!
    }

    private var currentSelection: CelestiaSelection? {
        guard let object = currentTree.selectedObjects.first as? CelestiaBrowserItem else { return nil }

        return transform(object)
    }

    private func transform(_ item: CelestiaBrowserItem) -> CelestiaSelection? {
        let object = item.entry
        if let star = object as? CelestiaStar {
            return CelestiaSelection(star: star)
        } else if let dso = object as? CelestiaDSO {
            return CelestiaSelection(dso: dso)
        } else if let b = object as? CelestiaBody {
            return CelestiaSelection(body: b)
        } else if let l = object as? CelestiaLocation {
            return CelestiaSelection(location: l)
        } else {
            return nil
        }
    }

    private let core: CelestiaAppCore = AppDelegate.shared.core
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

        if let item = (sender.item(atRow: clickedRow) as? NSTreeNode)?.representedObject as? CelestiaBrowserItem, let sel = transform(item) {
            core.simulation.selection = sel
            core.charEnter(103)
        }
    }
}

extension BrowserViewController: NSTabViewDelegate {
}

