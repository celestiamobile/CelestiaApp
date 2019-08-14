//
//  InfoViewController.swift
//  Celestia
//
//  Created by Li Linfeng on 14/8/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa
import CelestiaCore

class InfoViewController: NSViewController {
    private let core: CelestiaAppCore = AppDelegate.shared.core

    var selection: CelestiaSelection!

    @IBOutlet var contentTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func openWebURL(_ sender: Any) {
        if let urlStr = selection.webInfoURL, let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }
}
