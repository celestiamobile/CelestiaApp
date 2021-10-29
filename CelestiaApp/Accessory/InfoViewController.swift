//
// InfoViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Cocoa
import CelestiaCore

class InfoViewController: NSViewController {
    private let core: AppCore = AppCore.shared

    private let selection: Selection

    private lazy var webInfoButton: NSButton = {
        let button = NSButton()
        button.title = CelestiaString("Open Web URL", comment: "")
        button.setButtonType(.momentaryPushIn)
        button.bezelStyle = .rounded
        button.action = #selector(openWebURL(_:))
        button.target = self
        return button
    }()
    private lazy var contentTextView = NSTextView()
    private lazy var textViewContainer: NSScrollView = {
        let view = NSScrollView()
        view.borderType = .noBorder
        view.hasVerticalScroller = true
        view.hasHorizontalScroller = false
        view.documentView = contentTextView
        view.drawsBackground = false
        return view
    }()

    init(selection: Selection) {
        self.selection = selection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let container = NSView()
        contentTextView.drawsBackground = false
        contentTextView.autoresizingMask = [.width]
        contentTextView.isEditable = false
        webInfoButton.translatesAutoresizingMaskIntoConstraints = false
        textViewContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webInfoButton)
        container.addSubview(textViewContainer)

        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: textViewContainer, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: textViewContainer, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: textViewContainer, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: webInfoButton, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: webInfoButton, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: webInfoButton, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: webInfoButton, attribute: .top, relatedBy: .equal, toItem: textViewContainer, attribute: .bottom, multiplier: 1, constant: 20),

            NSLayoutConstraint(item: textViewContainer, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 200),
            NSLayoutConstraint(item: textViewContainer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 250),
        ])

        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = core.simulation.universe.name(for: selection)
        webInfoButton.target = self
        webInfoButton.action = #selector(openWebURL(_:))

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
    
    @objc private func openWebURL(_ sender: Any) {
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
