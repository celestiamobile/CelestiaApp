//
//  BrowserItemAddition.swift
//  Celestia
//
//  Created by Li Linfeng on 2019/11/21.
//  Copyright © 2019 李林峰. All rights reserved.
//

import CelestiaCore

var sharedUniverseItem: CelestiaUniverse?

extension CelestiaBrowserItem {
    @objc var isLeaf: Bool {
        return children.count == 0
    }

    @objc var solarSystemObject: CelestiaBody? {
        return entry as? CelestiaBody
    }

    @objc var locationObject: CelestiaLocation? {
        return entry as? CelestiaLocation
    }

    @objc var dsoObject: CelestiaDSO? {
        return entry as? CelestiaDSO
    }

    @objc var starObject: CelestiaStar? {
        return entry as? CelestiaStar
    }
}
