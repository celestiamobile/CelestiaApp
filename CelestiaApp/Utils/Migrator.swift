//
// Migrator.swift
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

class Migrator {
    class var dbVersion: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: "dbVersion")
        }
        get {
            return UserDefaults.standard.integer(forKey: "dbVersion")
        }
    }

    class var supportedDBVersion: Int {
        return 2
    }

    class func tryToMigrate() {
        if dbVersion < supportedDBVersion {
            LegacyMigrator.tryToMigrate()
            migrateDBFrom1To2()
        }
    }

    class func migrateDBFrom1To2() {
        guard dbVersion == 1 else { return }

        let legacyRawBookmarks = UserDefaults.standard.array(forKey: "favorites") as? [[AnyHashable : Any]] ?? []
        let legacyBookmarks = legacyRawBookmarks.map { CelestiaFavorite(dictionary: $0) }
        let newBookmarks = legacyBookmarks.map { BookmarkNode(legacy: $0) }
        AppDelegate.shared.bookmarkController.storedBookmarks = newBookmarks
        AppDelegate.shared.bookmarkController.storeBookmarksToDisk()

        dbVersion = 2

        UserDefaults.standard.synchronize()
    }
}

extension BookmarkNode {
    convenience init(legacy: CelestiaFavorite) {
        self.init(name: legacy.name, url: legacy.url ?? "", isFolder: legacy.children != nil, children: (legacy.children ?? []).map { BookmarkNode(legacy: $0) })
    }
}
