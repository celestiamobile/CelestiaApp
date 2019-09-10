//
//  PathUtils.swift
//  Celestia
//
//  Created by Li Linfeng on 10/9/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Foundation

var defaultDataDirectory: URL = {
    return Bundle.main.url(forResource: "CelestiaResources", withExtension: nil)!
}()

var defaultConfigDirectory: URL = {
    return defaultDataDirectory.appendingPathComponent("celestia.cfg")
}()
