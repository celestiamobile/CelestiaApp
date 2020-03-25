//
//  BookmarkController.swift
//  Celestia
//
//  Created by Li Linfeng on 13/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

class BookmarkController: NSObject {
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
        // get fixedMenus
        var menuItems = Array(bookmarkMenu.items[0..<2])

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
                let menuItem = NSMenuItem(title: item.name, action: nil, keyEquivalent: "")
                let subItems = item.children.map { createMenuItem(for: $0) }
                let subMenu = NSMenu(title: "")
                subMenu.items = subItems
                menuItem.submenu = subMenu
                return menuItem
            }
            menuItems += storedBookmarks.map { createMenuItem(for: $0) }
        }
        bookmarkMenu.items = menuItems
    }

    @objc private func bookmarkMenuItemClicked(_ sender: NSMenuItem) {
        let bookmark = displayedBookmarks[sender.tag]
        CelestiaAppCore.shared.go(to: bookmark.url)
    }

    @IBAction private func addBookmark(_ sender: Any) {
        guard let newBookmark = CelestiaAppCore.shared.currentBookmark else { return }

        storedBookmarks.append(newBookmark)
        buildBookmarkMenu()
    }

    @IBAction private func organizeBookmarks(_ sender: Any) {
        if let existing = NSApp.findWindow(type: BookmarkOrganizerViewController.self) {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let vc = NSStoryboard(name: "Bookmark", bundle: nil).instantiateController(withIdentifier: "Organizer") as! BookmarkOrganizerViewController
        vc.controller = self
        let panel = NSPanel(contentViewController: vc)
        panel.makeKeyAndOrderFront(self)
    }
}
