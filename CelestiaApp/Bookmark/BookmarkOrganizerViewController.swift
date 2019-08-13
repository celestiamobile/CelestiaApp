//
//  BookmarkOrganizerViewController.swift
//  Celestia
//
//  Created by Li Linfeng on 13/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class BookmarkOrganizerViewController: NSViewController {
    @IBOutlet private weak var outlineView: NSOutlineView!
    @IBOutlet private var tree: NSTreeController!

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}

extension BookmarkOrganizerViewController: NSOutlineViewDelegate {
}
