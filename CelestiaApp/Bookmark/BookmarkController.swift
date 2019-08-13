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
    private var storedBookmarks: [BookmarkNode] = []

    func readBookmarks() {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let bookmarkFilePath = "\(path)/bookmark.json"
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: bookmarkFilePath))
            let bookmarks = try JSONDecoder().decode([BookmarkNode].self, from: data)
            storedBookmarks = bookmarks
            // TODO: build up the bookmark menu
        } catch let error {
            print("Bookmark reading error: \(error.localizedDescription)")
        }
    }

    @IBAction private func addBookmark(_ sender: Any) {
    }

    @IBAction private func organizeBookmarks(_ sender: Any) {
        let vc = NSStoryboard(name: "Bookmark", bundle: nil).instantiateController(withIdentifier: "Organizer") as! NSViewController
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
