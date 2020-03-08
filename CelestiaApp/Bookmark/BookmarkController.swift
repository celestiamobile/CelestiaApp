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

    func readBookmarks() {
        guard let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else {
            return
        }
        let bookmarkFilePath = "\(path)/bookmark.json"
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: bookmarkFilePath))
            let bookmarks = try JSONDecoder().decode([BookmarkNode].self, from: data)
            storedBookmarks = bookmarks
        } catch let error {
            print("Bookmark reading error: \(error.localizedDescription)")
        }
    }

    func storeBookmarks() {
        guard let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else {
            return
        }
        let bookmarkFilePath = "\(path)/bookmark.json"
        do {
            try JSONEncoder().encode(storedBookmarks).write(to: URL(fileURLWithPath: bookmarkFilePath))
        } catch let error {
            print("Bookmark writing error: \(error.localizedDescription)")
        }
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
        let vc = NSStoryboard(name: "Bookmark", bundle: nil).instantiateController(withIdentifier: "Organizer") as! BookmarkOrganizerViewController
        vc.controller = self
        let panel = NSPanel(contentViewController: vc)
        panel.makeKeyAndOrderFront(self)
    }
}

extension CelestiaAppCore {
    var currentBookmark: BookmarkNode? {
        let selection = simulation.selection
        if selection.isEmpty {
            return nil
        }
        let name: String
        if let star = selection.star {
            name = simulation.universe.starCatalog.starName(star)
        } else if let body = selection.body {
            name = body.name
        } else if let dso = selection.dso {
            name = simulation.universe.dsoCatalog.dsoName(dso)
        } else if let location = selection.location {
            name = location.name
        } else {
            name = NSLocalizedString("Unknown", comment: "")
        }
        return BookmarkNode(name: name, url: currentURL, isFolder: false)
    }
}
