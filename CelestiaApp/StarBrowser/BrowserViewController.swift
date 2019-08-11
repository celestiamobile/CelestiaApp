//
//  BrowserViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/10.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

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

    private lazy var sol: BrowserItem = {
        let sol = core.simulation.universe.find("Sol")
        return BrowserItem(star: sol.star!)
    }()

    private var current: NSBrowser!

    private lazy var stars: BrowserItem = {
        func updateAccumulation(result: inout [String : BrowserItem], star: CelestiaStar) {
            result[core.simulation.universe.starCatalog.starName(star)] = BrowserItem(star: star)
        }

        let nearest = CelestiaStarBrowser(kind: .nearest, simulation: core.simulation).stars().reduce(into: [String : BrowserItem](), updateAccumulation)
        let brightest = CelestiaStarBrowser(kind: .brightest, simulation: core.simulation).stars().reduce(into: [String : BrowserItem](), updateAccumulation)
        let hasPlanets = CelestiaStarBrowser(kind: .starsWithPlants, simulation: core.simulation).stars().reduce(into: [String : BrowserItem](), updateAccumulation)

        let stars = BrowserItem(name: "")
        stars.addChild(BrowserItem(name: "Nearest Stars", children: nearest))
        stars.addChild(BrowserItem(name: "Brightest Stars", children: brightest))
        stars.addChild(BrowserItem(name: "Stars With Planets", children: hasPlanets))

        return stars
    }()

    private lazy var dso: BrowserItem = {
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

        func updateAccumulation(result: inout [String : BrowserItem], item: (key: String, value: [String : BrowserItem])) {
            let fullName = typeMap[item.key]!
            result[fullName] = BrowserItem(name: fullName, children: item.value)
        }

        let prefixes = ["SB", "S", "E", "Irr", "Neb", "Glob", "Clust"]

        var tempDict = prefixes.reduce(into: [String : [String : BrowserItem]]()) { $0[$1] = [String : BrowserItem]() }

        let catalog = core.simulation.universe.dsoCatalog
        catalog.forEach({ (dso) in
            let matchingType = prefixes.first(where: {dso.type.hasPrefix($0)}) ?? "Unknown"
            let name = catalog.dsoName(dso)
            tempDict[matchingType]![name] = BrowserItem(dso: dso)
        })

        let results = tempDict.reduce(into: [String : BrowserItem](), updateAccumulation)
        return BrowserItem(name: "", children: results)
    }()

    private var root: BrowserItem {
        return [
            "solarSystem" : self.sol,
            "star" : self.stars,
            "dso" : self.dso,
        ][rootID]!
    }

    func item(at pathArray: [String]) -> BrowserItem {
        var lastItem = root
        var nextItem: BrowserItem? = lastItem

        for i in 1..<pathArray.count {
            let lastKey = pathArray[i]
            nextItem = lastItem.child(with: lastKey)
            if nextItem == nil {
                break
            }
            lastItem = nextItem!
        }

        if let item = nextItem {
            BrowserItem.addChildrenIfAvailable(item, in: core.simulation.universe)
        }
        return lastItem
    }

    func selection(at pathArray: [String]) -> CelestiaSelection? {
        let body = item(at: pathArray).body
        if let star = body as? CelestiaStar {
           return CelestiaSelection(star: star)
        } else if let dso = body as? CelestiaDSO {
            return CelestiaSelection(dso: dso)
        } else if let b = body as? CelestiaBody {
            return CelestiaSelection(body: b)
        } else if let l = body as? CelestiaLocation {
            return CelestiaSelection(location: l)
        }
        return nil
    }

    private let core: AppCore = AppDelegate.shared.core

    private var rootID: String = "solarSystem"

    @IBAction private func commonAction(_ sender: NSButton) {
        if let sel = selection(at: current.path().components(separatedBy: current.pathSeparator)) {
            core.simulation.selection = sel
            if sender.tag != 0 {
                core.charEnter(unichar(sender.tag))
            }
        }
    }

    @IBAction private func doubleClick(_ sender: NSBrowser) {
        if let sel = selection(at: current.path().components(separatedBy: current.pathSeparator)) {
            core.simulation.selection = sel
            core.charEnter(103)
        }
    }
}

extension BrowserViewController: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        rootID = tabViewItem?.identifier as? String ?? ""
    }
}

extension BrowserViewController: NSBrowserDelegate {
    func browser(_ sender: NSBrowser, numberOfRowsInColumn column: Int) -> Int {
        if current != sender {
            current = sender
            current.target = self
            current.doubleAction = #selector(doubleClick(_:))
        }
        return Int(self.item(at: sender.path(toColumn: column).components(separatedBy: sender.pathSeparator)).childCount)
    }

    func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
        let itemForColumn = item(at: sender.path(toColumn: column).components(separatedBy: sender.pathSeparator))
        let itemName = itemForColumn.allChildNames[row]
        let isLeaf = BrowserItem.isLeaf(itemForColumn.child(with: itemName)!, in: core.simulation.universe)
        let actualCell = cell as! NSBrowserCell
        actualCell.title = itemForColumn.allChildNames[row]
        actualCell.isLeaf = isLeaf
    }
}
