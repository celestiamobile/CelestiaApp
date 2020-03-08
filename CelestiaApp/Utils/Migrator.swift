//
//  Migrator.swift
//  Celestia
//
//  Created by Li Linfeng on 8/10/2019.
//  Copyright © 2019 李林峰. All rights reserved.
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
