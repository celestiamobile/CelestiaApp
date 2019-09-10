//
//  ConfigSelectionWindowController.swift
//  Celestia
//
//  Created by Li Linfeng on 10/9/2019.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class ConfigSelectionWindowController: NSWindowController {

    @IBOutlet private weak var cancelButton: NSButton!
    @IBOutlet private weak var configPathControl: NSPathControl!
    @IBOutlet private weak var dataPathControl: NSPathControl!

    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @IBAction func cancel(_ sender: Any) {
    }

    @IBAction func reset(_ sender: Any) {
    }

    @IBAction func confirm(_ sender: Any) {
    }
}
