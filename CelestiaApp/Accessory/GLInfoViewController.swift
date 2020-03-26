//
//  GLInfoViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

import CelestiaCore

class GLInfoViewController: NSViewController {

    @IBOutlet var infoTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        infoTextView.string = CelestiaAppCore.shared.renderInfo
    }
    
}
