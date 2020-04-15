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
    private let core: CelestiaAppCore = CelestiaAppCore.shared

    var selection: CelestiaSelection!

    @IBOutlet private var webInfoButton: NSButton!
    @IBOutlet private var contentTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let attr = NSMutableAttributedString()
        attr.appendPrimaryText(core.simulation.universe.name(for: selection))
        attr.appendEmptyLine()
        attr.appendSecondaryText(core.overviewForSelection(selection))

        contentTextView.textStorage?.setAttributedString(attr)

        if let urlStr = selection.webInfoURL, URL(string: urlStr) != nil {
            webInfoButton.isEnabled = true
        } else {
            webInfoButton.isEnabled = false
        }
    }
    
    @IBAction func openWebURL(_ sender: Any) {
        if let urlStr = selection.webInfoURL, let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }
}

extension NSMutableAttributedString {
    func appendPrimaryText(_ string: String) {
        append(NSAttributedString(string: string, attributes: [
            .foregroundColor : NSColor.labelColor,
            .font : NSFont.systemFont(ofSize: 17)
        ]))
    }

    func appendSecondaryText(_ string: String) {
        append(NSAttributedString(string: string, attributes: [
            .foregroundColor : NSColor.secondaryLabelColor,
            .font : NSFont.systemFont(ofSize: 13)
        ]))
    }

    func appendLineBreak(count: Int = 1) {
        appendSecondaryText(String(repeating: "\n", count: count))
    }

    func appendEmptyLine(count: Int = 1) {
        appendLineBreak(count: 2 * count)
    }
}
