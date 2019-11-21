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

    private lazy var sol: CelestiaBrowserItem = {
        let sol = universe.find("Sol")
        return CelestiaBrowserItem(catEntry: sol.star!, provider: universe)
    }()

    private var current: NSBrowser!

    private lazy var stars: CelestiaBrowserItem = {
        func updateAccumulation(result: inout [String : CelestiaBrowserItem], star: CelestiaStar) {
            result[universe.starCatalog.starName(star)] = CelestiaBrowserItem(catEntry: star, provider: universe)
        }

        let nearest = CelestiaStarBrowser(kind: .nearest, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
        let brightest = CelestiaStarBrowser(kind: .brightest, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
        let hasPlanets = CelestiaStarBrowser(kind: .starsWithPlants, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)

        let nearestName = NSLocalizedString("Nearest Stars", comment: "")
        let brightestName = NSLocalizedString("Brightest Stars", comment: "")
        let hasPlanetsName = NSLocalizedString("Stars With Planets", comment: "")
        let stars = CelestiaBrowserItem(name: "", children: [
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
            tempDict[matchingType]![name] = CelestiaBrowserItem(catEntry: dso, provider: universe)
        })

        let results = tempDict.reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
        return CelestiaBrowserItem(name: "", children: results)
    }()

    private var root: CelestiaBrowserItem {
        return [
            "solarSystem" : self.sol,
            "star" : self.stars,
            "dso" : self.dso,
        ][rootID]!
    }

    func item(at pathArray: [String]) -> CelestiaBrowserItem {
        var lastItem = root
        var nextItem: CelestiaBrowserItem? = lastItem

        for i in 1..<pathArray.count {
            let lastKey = pathArray[i]
            nextItem = lastItem.child(with: lastKey)
            if nextItem == nil {
                break
            }
            lastItem = nextItem!
        }

        return lastItem
    }

    func selection(at pathArray: [String]) -> CelestiaSelection? {
        let body = item(at: pathArray).entry
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

    private let core: CelestiaAppCore = AppDelegate.shared.core
    private lazy var universe: CelestiaUniverse = self.core.simulation.universe

    private var rootID: String = "solarSystem"

    @IBAction private func commonAction(_ sender: NSButton) {
        if let sel = selection(at: current.path().components(separatedBy: current.pathSeparator)) {
            core.simulation.selection = sel
            if sender.tag != 0 {
                core.charEnter(Int8(sender.tag))
            }
        }
    }

    @objc private func doubleClick(_ sender: NSBrowser) {
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
        return Int(self.item(at: sender.path(toColumn: column).components(separatedBy: sender.pathSeparator)).children.count)
    }

    func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
        let itemForColumn = item(at: sender.path(toColumn: column).components(separatedBy: sender.pathSeparator))
        let itemName = itemForColumn.childName(at: row)!
        let child = itemForColumn.child(with: itemName)!
        let actualCell = cell as! NSBrowserCell
        actualCell.title = itemName
        actualCell.isLeaf = child.children.count == 0
    }
}
