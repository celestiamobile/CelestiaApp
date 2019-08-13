//
//  BookmarkNode.swift
//  Celestia
//
//  Created by Li Linfeng on 13/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class BookmarkNode: NSObject {
    let isFolder: Bool

    @objc var name: String
    @objc var children: [BookmarkNode]

    init(name: String, isFolder: Bool, children: [BookmarkNode] = []) {
        self.name = name
        self.isFolder = isFolder
        self.children = children
        super.init()
    }

    @objc func isLeaf() -> Bool {
        return !isFolder
    }
}
