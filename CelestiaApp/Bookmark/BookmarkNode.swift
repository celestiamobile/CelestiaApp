//
//  BookmarkNode.swift
//  Celestia
//
//  Created by Li Linfeng on 13/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

final class BookmarkNode: NSObject {
    let isFolder: Bool

    @objc var name: String
    @objc var url: String
    @objc var children: [BookmarkNode]

    init(name: String, url: String, isFolder: Bool, children: [BookmarkNode] = []) {
        self.name = name
        self.url = url
        self.isFolder = isFolder
        self.children = children
        super.init()
    }

    @objc var isLeaf: Bool {
        return !isFolder
    }
}

extension BookmarkNode: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case isFolder
        case children
    }
}
