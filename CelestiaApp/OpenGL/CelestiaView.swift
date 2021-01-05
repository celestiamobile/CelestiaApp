//
// CelestiaGLView.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Cocoa

protocol CelestiaViewDelegate: class {
    func draw(in glView: CelestiaView)
    func update(in glView: CelestiaView)
    func initialize(with context: NSOpenGLContext, supportsMultiThread: Bool, callback: @escaping (Bool) -> Void)
}

class CelestiaView: NSOpenGLView {
    weak var viewDelegate: CelestiaViewDelegate?
    weak var mouseProcessor: CelestiaViewMouseProcessor?
    weak var keyboardProcessor: CelestiaViewKeyboardProcessor?
    weak var dndProcessor: CelestiaViewDNDProcessor?

    private let mouseDragThreshold: CGFloat = 3
    private var mouseMotion: CGFloat = 0

    private var cursorVisible: Bool = true
    private var supportsMultiThread: Bool = false
    private var msaaEnabled: Bool = false

    private var displayLink: CVDisplayLink?

    private var currentSize: CGSize = .zero
    private var ready = false

    private var displaySource: DispatchSourceUserDataAdd?

    var scaleFactor: CGFloat {
        get { return layer?.contentsScale ?? 1.0 }
        set { layer?.contentsScale = newValue }
    }

    init?(frame frameRect: NSRect, pixelFormat format: NSOpenGLPixelFormat?, msaaEnabled: Bool) {
        super.init(frame: frameRect, pixelFormat: format)

        self.msaaEnabled = msaaEnabled

        setupGL()
        setupDND()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if let link = displayLink {
            CVDisplayLinkStop(link)
            displaySource?.cancel()
            displaySource = nil
        }
        if let window = newWindow {
            setupDisplayLink(with: window)
        }
    }

    override var isFlipped: Bool {
        return true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        window?.acceptsMouseMovedEvents = window != nil
    }

    // MARK: Mouse
    override func mouseUp(with event: NSEvent) {
        if event.modifierFlags.contains(NSEvent.ModifierFlags.option) {
            rightMouseUp(with: event)
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

        if !cursorVisible {
            CGAssociateMouseAndMouseCursorPosition(1)
            NSCursor.unhide()
            cursorVisible = true
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)

        mouseMotion = 0

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

        let offset = CGPoint(x: event.deltaX, y: event.deltaY)
        mouseMotion += (abs(offset.x) + abs(offset.y))

        if NSCursor.current == NSCursor.arrow && cursorVisible && mouseMotion > mouseDragThreshold  {
            NSCursor.hide()
            CGAssociateMouseAndMouseCursorPosition(0)
            cursorVisible = false
        }

        mouseProcessor?.mouseMove(by: offset, modifiers: event.modifierFlags, with: .left)
    }

    override func rightMouseUp(with event: NSEvent) {
        mouseProcessor?.mouseUp(at: convert(event.locationInWindow, from: nil), modifiers: event.modifierFlags, with: .right)

        if !cursorVisible {
            CGAssociateMouseAndMouseCursorPosition(1)
            NSCursor.unhide()
            cursorVisible = true
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        mouseMotion = 0

        mouseProcessor?.mouseDown(at: convert(event.locationInWindow, from: nil), modifiers: event.modifierFlags, with: .right)
    }

    override func rightMouseDragged(with event: NSEvent) {
        let offset = CGPoint(x: event.deltaX, y: event.deltaY)

        mouseMotion += (abs(offset.x) + abs(offset.y))

        if cursorVisible && mouseMotion > mouseDragThreshold {
            NSCursor.hide()
            CGAssociateMouseAndMouseCursorPosition(0)
            cursorVisible = false
        }

        mouseProcessor?.mouseMove(by: offset, modifiers: event.modifierFlags, with: .right)
    }

    override func otherMouseUp(with event: NSEvent) {
        mouseProcessor?.mouseUp(at: convert(event.locationInWindow, from: nil), modifiers: event.modifierFlags, with: .middle)
    }

    override func otherMouseDown(with event: NSEvent) {
        mouseMotion = 0

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

    // MARK: Responder
    override var acceptsFirstResponder: Bool { return true }

    override func resignFirstResponder() -> Bool { return true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }

    // MARK: Drag and Drop
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let path = sender.draggingPasteboard.string(forType: .init(kUTTypeFileURL as String)), let url = URL(string: path) {
            return dndProcessor?.draggingType(for: url) ?? NSDragOperation()
        }
        return NSDragOperation()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let path = sender.draggingPasteboard.string(forType: .init(kUTTypeFileURL as String)), let url = URL(string: path) {
            dndProcessor?.performDrop(for: url)
        }
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        if let context = openGLContext {
            viewDelegate?.draw(in: self)
            context.flushBuffer()
        }
    }

    override func update() {
        super.update()

        viewDelegate?.update(in: self)
    }

    override func reshape() {
        super.reshape()

        viewDelegate?.update(in: self)
    }

    @objc private func displayLinkCallback() {
        guard ready else { return }

        needsDisplay = true
    }
}

extension CelestiaView {
    private func setupGL() {
        guard let context = openGLContext else { return }

        if let obj = context.cglContextObj, CGLEnable(obj, CGLContextEnable(313)).rawValue == 0 {
            print("Multithreaded OpenGL enabled.")
            supportsMultiThread = true
        }

        var swapInterval: GLint = 1
        context.setValues(&swapInterval, for: NSOpenGLContext.Parameter.swapInterval)

        context.makeCurrentContext()

        if msaaEnabled {
            context.enable(0x809D)
        }
    }

    private func setupDisplayLink(with window: NSWindow) {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if let link = displayLink {
            if displaySource == nil {
                let source = DispatchSource.makeUserDataAddSource(queue: .main)
                source.setEventHandler() { [weak self] in
                    self?.displayLinkCallback()
                }
                source.resume()
                displaySource = source
            }
            CVDisplayLinkSetOutputCallback(link, { (link, now, outputTime, flagsIn, flagsOut, context) -> CVReturn in
                let displaySource = Unmanaged<DispatchSourceUserDataAdd>.fromOpaque(context!).takeUnretainedValue()
                displaySource.add(data: 1)
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(displaySource!).toOpaque())

            if let displayID = window.screen?.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID {
                CVDisplayLinkSetCurrentCGDisplay(link, displayID)
                CVDisplayLinkStart(link)
            }
        }
    }

    private func setupDND() {
        registerForDraggedTypes([.init(kUTTypeFileURL as String)])
    }

    func setupCelestia() {
        viewDelegate?.initialize(with: openGLContext!, supportsMultiThread: supportsMultiThread) { (success) in
            self.ready = success
        }
    }
}
