//
//  GLInfoViewController.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/11.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

class GLInfoViewController: NSViewController {

    @IBOutlet var infoTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        infoTextView.textStorage?.setAttributedString(NSAttributedString(string: CGLInfo.info))
    }
    
}
