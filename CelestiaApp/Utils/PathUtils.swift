//
//  PathUtils.swift
//  Celestia
//
//  Created by Li Linfeng on 10/9/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Foundation

let defaultDataDirectory: URL = {
    return Bundle.main.url(forResource: "CelestiaResources", withExtension: nil)!
}()

let defaultConfigFile: URL = {
    return defaultDataDirectory.appendingPathComponent("celestia.cfg")
}()

let extraDirectory: URL? = {
    let supportDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
    let parentDirectory = supportDirectory.appendingPathComponent("CelestiaResources")
    do {
        try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)
        let extraDirectory = parentDirectory.appendingPathComponent("extras")
        try FileManager.default.createDirectory(at: extraDirectory, withIntermediateDirectories: true, attributes: nil)
        let scriptDirectory = parentDirectory.appendingPathComponent("scripts")
        try FileManager.default.createDirectory(at: scriptDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch _ {
        return nil
    }
    return parentDirectory
}()

let extraScriptDirectory: URL? = extraDirectory?.appendingPathComponent("scripts")

func currentDataDirectory() -> URL {
    guard let bookmark = UserDefaults.standard.data(forKey: "dataDirPath") else { return defaultDataDirectory }

    var isStale: Bool = false
    guard let resolved = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { return defaultDataDirectory }

    guard resolved.startAccessingSecurityScopedResource() else { return defaultDataDirectory }

    return resolved
}

func currentConfigFile() -> URL {
    guard let bookmark = UserDefaults.standard.data(forKey: "configFilePath") else { return defaultConfigFile }

    var isStale: Bool = false
    guard let resolved = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { return defaultConfigFile }

    guard resolved.startAccessingSecurityScopedResource() else { return defaultConfigFile }

    return resolved
}

func saveDataDirectory(bookmark: Data?) {
    UserDefaults.standard.set(bookmark, forKey: "dataDirPath")
}

func saveConfigFile(bookmark: Data?) {
    UserDefaults.standard.set(bookmark, forKey: "configFilePath")
}
