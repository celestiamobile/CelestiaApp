//
//  BookmarkController.swift
//  Celestia
//
//  Created by Li Linfeng on 13/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class BookmarkController: NSObject {
    func readBookmarks() {
    }

    @IBAction private func addBookmark(_ sender: Any) {
    }

    @IBAction private func organizeBookmarks(_ sender: Any) {
        let vc = NSStoryboard(name: "Bookmark", bundle: nil).instantiateController(withIdentifier: "Organizer") as! NSViewController
        let panel = NSPanel(contentViewController: vc)
        panel.makeKeyAndOrderFront(self)
    }
}
