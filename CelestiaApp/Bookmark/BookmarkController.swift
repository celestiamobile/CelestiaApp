//
// BookmarkController.swift
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

class BookmarkController: NSObject {
    private var isConfigured = false

    var storedBookmarks: [BookmarkNode] = []
    var displayedBookmarks: [BookmarkNode] = []

    @IBOutlet weak var bookmarkMenu: NSMenu!

    func readBookmarksFromDisk() {
        storedBookmarks = readBookmarks()
    }

    func storeBookmarksToDisk() {
        storeBookmarks(storedBookmarks)
    }

    func buildBookmarkMenu() {
        // get fixed menu items
        var menuItems = Array(bookmarkMenu.items[0..<2])

        // clear all items
        bookmarkMenu.removeAllItems()

        displayedBookmarks = []

        if storedBookmarks.count > 0 {
            menuItems.append(.separator())
            func createMenuItem(for item: BookmarkNode) -> NSMenuItem {
                if !item.isFolder {
                    let menuItem = NSMenuItem(title: item.name, action: #selector(bookmarkMenuItemClicked(_:)), keyEquivalent: "")
                    menuItem.target = self
                    menuItem.tag = displayedBookmarks.count
                    displayedBookmarks.append(item)
                    return menuItem
                }
                let subMenu = NSMenu(title: "")
                let menuItem = NSMenuItem(title: item.name, action: nil, keyEquivalent: "")
                for child in item.children {
                    subMenu.addItem(createMenuItem(for: child))
                }
                menuItem.submenu = subMenu
                return menuItem
            }
            menuItems += storedBookmarks.map { createMenuItem(for: $0) }
        }
        for item in menuItems {
            bookmarkMenu.addItem(item)
        }
        isConfigured = true
    }

    @objc private func bookmarkMenuItemClicked(_ sender: NSMenuItem) {
        let bookmark = displayedBookmarks[sender.tag]
        CelestiaAppCore.shared.go(to: bookmark.url)
    }

    @IBAction private func addBookmark(_ sender: Any) {
        guard isConfigured else { return }

        guard let newBookmark = CelestiaAppCore.shared.currentBookmark else { return }

        storedBookmarks.append(newBookmark)
        buildBookmarkMenu()
    }

    @IBAction private func organizeBookmarks(_ sender: Any) {
        guard isConfigured else { return }

        AppDelegate.present(identifier: "Bookmark") { () -> BookmarkOrganizerViewController in
            let vc = NSStoryboard(name: "Bookmark", bundle: nil).instantiateController(withIdentifier: "Organizer") as! BookmarkOrganizerViewController
            vc.controller = self
            return vc
        }
    }

    deinit {
        AppDelegate.clear(identifier: "Bookmark")
    }
}
