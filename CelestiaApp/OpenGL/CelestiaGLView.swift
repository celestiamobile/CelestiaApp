//
//  CelestiaGLView.swift
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/9.
//  Copyright © 2019 李林峰. All rights reserved.
//

import Cocoa

typealias CelestiaGLViewMouseButton = CelestiaViewMouseButton;
typealias CelestiaGLViewMouseProcessor = CelestiaViewMouseProcessor;
typealias CelestiaGLViewKeyboardProcessor = CelestiaViewKeyboardProcessor;
typealias CelestiaGLViewDNDProcessor = CelestiaViewDNDProcessor;

protocol CelestiaGLViewDelegate: class {
    func draw(in glView: CelestiaGLView)
    func update(in glView: CelestiaGLView)
}

class CelestiaGLView: NSOpenGLView {
    weak var delegate: CelestiaGLViewDelegate?
    weak var mouseProcessor: CelestiaGLViewMouseProcessor?
    weak var keyboardProcessor: CelestiaGLViewKeyboardProcessor?
    weak var dndProcessor: CelestiaGLViewDNDProcessor?

    private let mouseDragThreshold: CGFloat = 3
    private var mouseMotion: CGFloat = 0

    private var cursorVisible: Bool = true

    private var displayLink: CVDisplayLink?

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        setupGL()
        setupDisplayLink()
        setupDND()
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

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil, let link = displayLink {
            CVDisplayLinkStop(link)
        }
    }

    func displayLinkCallback() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.needsDisplay = true
        }
    }
}

extension CelestiaGLView {
    private func setupGL() {
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

    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if let link = displayLink {
            CVDisplayLinkSetOutputCallback(link, { (link, now, outputTime, flagsIn, flagsOut, context) -> CVReturn in
                let view = Unmanaged<CelestiaGLView>.fromOpaque(context!).takeUnretainedValue()
                view.displayLinkCallback()
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())

            if let cglContext = openGLContext?.cglContextObj, let cglPixelFormat = pixelFormat?.cglPixelFormatObj {
                CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(link, cglContext, cglPixelFormat)
                CVDisplayLinkStart(link)
            }
        }
    }

    private func setupDND() {
        registerForDraggedTypes([.init(kUTTypeFileURL as String)])
    }
}
