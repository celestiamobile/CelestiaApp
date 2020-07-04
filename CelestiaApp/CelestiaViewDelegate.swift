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

    static let left = CelestiaGLViewMouseButton(rawValue: 1 << 0)
    static let middle = CelestiaGLViewMouseButton(rawValue: 1 << 1)
    static let right = CelestiaGLViewMouseButton(rawValue: 1 << 2)

    static let all: CelestiaGLViewMouseButton = [.left, .middle, .right]
}

protocol CelestiaViewMouseProcessor: class {
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton)
    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton)
    func mouseMove(by offset: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: CelestiaGLViewMouseButton)
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
