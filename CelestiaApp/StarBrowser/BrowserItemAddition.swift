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

extension BrowserItem {
    @objc var isLeaf: Bool {
        return children.count == 0
    }

    @objc var solarSystemObject: Body? {
        return entry as? Body
    }

    @objc var locationObject: Location? {
        return entry as? Location
    }

    @objc var dsoObject: DSO? {
        return entry as? DSO
    }

    @objc var starObject: Star? {
        return entry as? Star
    }
}
