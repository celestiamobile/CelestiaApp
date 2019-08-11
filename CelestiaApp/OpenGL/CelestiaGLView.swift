//
//  CelestiaGLView.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/9.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

protocol CelestiaGLViewDelegate: class {
    func draw(in glView: CelestiaGLView)
    func update(in glView: CelestiaGLView)
}

protocol CelestiaGLViewMouseProcessor: class {
    func mouseUp(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: MouseButton)
    func mouseDown(at point: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: MouseButton)
    func mouseMove(by offset: CGPoint, modifiers: NSEvent.ModifierFlags, with buttons: MouseButton)
    func mouseDragged(to point: CGPoint)
    func mouseWheel(by motion: CGFloat, modifiers: NSEvent.ModifierFlags)

    func requestMenu(at point: NSPoint) -> NSMenu?
}

protocol CelestiaGLViewKeyboardProcessor: class {
    func keyUp(modifiers: NSEvent.ModifierFlags, with input: String?)
    func keyDown(modifiers: NSEvent.ModifierFlags, with input: String?)
}

extension NSEvent {
    var input: String? {
        if let c = characters, c.count > 0 {
            return c
        }
        return charactersIgnoringModifiers
    }
}

class CelestiaGLView: NSOpenGLView {
    weak var delegate: CelestiaGLViewDelegate?
    weak var mouseProcessor: CelestiaGLViewMouseProcessor?
    weak var keyboardProcessor: CelestiaGLViewKeyboardProcessor?

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        setup()
    }

    override func draw(_ dirtyRect: NSRect) {
        if let context = openGLContext {
            delegate?.draw(in: self)
            context.flushBuffer()
        }
    }

    override func update() {
        delegate?.update(in: self)

        super.update()
    }

    override var isFlipped: Bool {
        return true
    }

    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
    }

    // MARK: Mouse
    override func mouseUp(with event: NSEvent) {
        if event.modifierFlags.contains(NSEvent.ModifierFlags.option) {
            otherMouseUp(with: event)
            return
        }

        var location = convert(event.locationInWindow, from: nil)
        if !bounds.contains(location) {
            // -ve coords can crash Celestia so clamp to view bounds
            if location.x < bounds.minX { location.x = bounds.minX }
            if location.x > bounds.maxX { location.x = bounds.maxX }

            if location.y < bounds.minY { location.y = bounds.minY }
            if location.y > bounds.maxY { location.y = bounds.maxY }
        }

        mouseProcessor?.mouseUp(at: location, modifiers: event.modifierFlags, with: .left)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)

        let location = convert(event.locationInWindow, from: nil)
        mouseProcessor?.mouseDown(at: location, modifiers: event.modifierFlags, with: .left)
    }

    override func mouseMoved(with event: NSEvent) {
        mouseProcessor?.mouseDragged(to: convert(event.locationInWindow, from: nil))
    }

    override func mouseDragged(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            rightMouseDragged(with: event)
            return
        }

        mouseProcessor?.mouseMove(by: CGPoint(x: event.deltaX, y: event.deltaY), modifiers: event.modifierFlags, with: .left)
    }

    override func rightMouseUp(with event: NSEvent) {
        mouseProcessor?.mouseUp(at: convert(event.locationInWindow, from: nil), modifiers: event.modifierFlags, with: .right)

        if event.clickCount > 0 {
            //...Force context menu to appear only on clicks (not drags)
            if let menu = mouseProcessor?.requestMenu(at: convert(event.locationInWindow, from: nil)) {
                NSMenu.popUpContextMenu(menu, with: event, for: self)
            }
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        mouseProcessor?.mouseDown(at: convert(event.locationInWindow, from: nil), modifiers: event.modifierFlags, with: .right)
    }

    override func rightMouseDragged(with event: NSEvent) {
        mouseProcessor?.mouseMove(by: CGPoint(x: event.deltaX, y: event.deltaY), modifiers: event.modifierFlags, with: .right)
    }

    override func otherMouseUp(with event: NSEvent) {
        mouseProcessor?.mouseUp(at: convert(event.locationInWindow, from: nil), modifiers: event.modifierFlags, with: .middle)
    }

    override func otherMouseDown(with event: NSEvent) {
        mouseProcessor?.mouseDown(at: convert(event.locationInWindow, from: nil), modifiers: event.modifierFlags, with: .middle)
    }

    override func otherMouseDragged(with event: NSEvent) {
        mouseProcessor?.mouseMove(by: CGPoint(x: event.deltaX, y: event.deltaY), modifiers: event.modifierFlags, with: .middle)
    }

    override func scrollWheel(with event: NSEvent) {
        mouseProcessor?.mouseWheel(by: event.deltaY, modifiers: event.modifierFlags)
    }

    // MARK: Key
    override func keyUp(with event: NSEvent) {
        keyboardProcessor?.keyUp(modifiers: event.modifierFlags, with: event.input)
    }

    override func keyDown(with event: NSEvent) {
        keyboardProcessor?.keyDown(modifiers: event.modifierFlags, with: event.input)
    }

    // MARK: Menu
    override func menu(for event: NSEvent) -> NSMenu? {
        return mouseProcessor?.requestMenu(at: convert(event.locationInWindow, from: nil))
    }

    // MARK: Responder
    override var acceptsFirstResponder: Bool { return true }

    override func resignFirstResponder() -> Bool { return true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
}

extension CelestiaGLView {
    func setup() {
        let attributes = [UInt32(NSOpenGLPFADoubleBuffer), UInt32(NSOpenGLPFADepthSize), 32, 0]
        let format = NSOpenGLPixelFormat(attributes: attributes)
        pixelFormat = format

        if let cglContext = openGLContext?.cglContextObj, CGLEnable(cglContext, CGLContextEnable.init(313)).rawValue == 0 {
            print("Multithreaded OpenGL enabled.")
        } else {
            print("Multithreaded OpenGL not supported on your system.")
        }

        var swapInterval: GLint = 1
        openGLContext?.setValues(&swapInterval, for: .swapInterval)
    }
}
