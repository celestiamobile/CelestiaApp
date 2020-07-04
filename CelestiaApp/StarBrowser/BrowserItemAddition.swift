//
// BrowserItemAddition.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore

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
