//
// CelestiaViewDelegate.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Cocoa

struct CelestiaViewMouseButton: OptionSet {
    let rawValue: UInt

    static let left = CelestiaViewMouseButton(rawValue: 1 << 0)
    static let middle = CelestiaViewMouseButton(rawValue: 1 << 1)
    static let right = CelestiaViewMouseButton(rawValue: 1 << 2)

    static let all: CelestiaViewMouseButton = [.left, .middle, .right]
}

protocol CelestiaViewMouseProcessor: class {
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton)
    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton)
    func mouseMove(by offset: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaViewMouseButton)
    func mouseDragged(to point: CGPoint)
    func mouseWheel(by motion: CGFloat, modifiers: NSEvent.ModifierFlags)
}

protocol CelestiaViewKeyboardProcessor: class {
    func keyUp(modifiers: NSEvent.ModifierFlags, with input: String?)
    func keyDown(modifiers: NSEvent.ModifierFlags, with input: String?)
}

protocol CelestiaViewDNDProcessor: class {
    func draggingType(for url: URL) -> NSDragOperation
    func performDrop(for url: URL)
}

extension NSEvent {
    var input: String? {
        if let c = characters, c.count > 0 {
            return c
        }
        return charactersIgnoringModifiers
    }
}
