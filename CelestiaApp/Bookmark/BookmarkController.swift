//
//  BookmarkController.swift
//  Celestia
//
//  Created by Li Linfeng on 13/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

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
