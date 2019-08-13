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
    var storedBookmarks: [BookmarkNode] = [] { didSet { buildBookmarkMenu() } }

    @IBOutlet weak var bookmarkMenu: NSMenu!

    func readBookmarks() {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
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
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
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

        // first 5 bookmarks that are not in a folder
        let topLevelBookmarks = storedBookmarks.filter { !$0.isFolder }
        let menuBookmarks = topLevelBookmarks.count > 5 ? Array(topLevelBookmarks[0..<5]) : topLevelBookmarks

        if menuBookmarks.count > 0 {
            menuItems.append(.separator())
            for i in 0..<menuBookmarks.count {
                let bookmark = menuBookmarks[i]
                let item = NSMenuItem(title: bookmark.name, action: #selector(bookmarkMenuItemClicked(_:)), keyEquivalent: "")
                item.target = self
                item.tag = i
                menuItems.append(item)
            }
        }
        bookmarkMenu.items = menuItems
    }

    @objc private func bookmarkMenuItemClicked(_ sender: NSMenuItem) {
        let bookmark = storedBookmarks[sender.tag]
        AppDelegate.shared.core.go(to: bookmark.url)
    }

    @IBAction private func addBookmark(_ sender: Any) {
        guard let newBookmark = AppDelegate.shared.core.currentBookmark else { return }

        storedBookmarks.append(newBookmark)
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
